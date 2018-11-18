//
//  TBSMTPTransporter.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import "TBSMTPTransporter.h"

#import "GCDAsyncSocket.h"

#import "TBSMTPResponse.h"
#import "TBSMTPAuthenticator.h"

#import "NSString+Coding.h"
#import "NSString+Hash.h"

#import "NSArray+indexOfNumber.h"

#define kTransporterConnectTimeout				10.
#define kTransporterProtocolTimeout				30.

#define DISPATCH_TIME_SMTP_TIMEOUT	dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTransporterProtocolTimeout * NSEC_PER_SEC))


@interface TBSMTPTransporter () <GCDAsyncSocketDelegate>

@property (retain) GCDAsyncSocket	*socket;
@property (assign, readwrite)		TBSMTPProtocolProgressIndicator protocolProgressIndicator;

@property (retain) TBSMTPResponse	*lastResponse;
@property (retain) TBSMTPRequest	*lastRequest;

@end


@interface TBSMTPTransporter (SMTPImplementation)

- (BOOL)connect;
- (void)disconnect;

- (BOOL)ehlo;
- (BOOL)authenticate;
- (BOOL)mailFrom;
- (BOOL)rcptTo;
- (BOOL)data;
- (BOOL)sendMessage;
- (BOOL)quit;

@end

@interface TBSMTPTransporter (Validation)

- (BOOL)lastResponseHasSuccessCodeWithSuccessCodesArray:(NSArray *)successCodes;
- (NSError *)errorForSMTPResponseType:(TBSMTPResponseType)responseType;

@end


@implementation TBSMTPTransporter

@synthesize protocolProgressIndicator = _protocolProgressIndicator;
@synthesize message = _message;
@synthesize server = _server;
@synthesize error = _error;
@synthesize lastResponse = _lastResponse;
@synthesize lastRequest = _lastRequest;
@synthesize socket = _socket;

#pragma mark - Object Lifecycle

- (id)initWithMessage:(TBSMTPMessage *)message andServer:(TBSMTPServer *)server {
    
    self = [super init];
    if (self) {
        _message		= [message retain];
        _server			= [server retain];
        _socket			= nil;
        _error			= nil;
        _lastResponse	= nil;
        _lastRequest	= nil;
        _protocolProgressIndicator = TBSMTPResponseType_NOT_SPECIFIED;
        
        _connectionSemaphore = dispatch_semaphore_create(0);
        _readSemaphore	= dispatch_semaphore_create(0);
        _writeSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}


- (void)dealloc {
    [_message release]; _message = nil;
    [_server release];	_server  = nil;

    [self disconnect];
    [_socket release]; _socket = nil;
    dispatch_release(_connectionQueue);
    
    [_error release]; _error = nil;
    [_lastResponse release]; _lastResponse = nil;
    [_lastRequest release]; _lastRequest = nil;

    dispatch_release(_connectionSemaphore);
    dispatch_release(_readSemaphore);
    dispatch_release(_writeSemaphore);

    [super dealloc];
}

#pragma mark - main behaviour

- (void)main {

    
    BOOL result = NO;

    _connectionQueue = dispatch_queue_create("transporterConnectionQueue", NULL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_connectionQueue];

    //
    //	connect
    //

    result = [self connect];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_CONNECTION_ESTABLISHMENT];
        return;
    }

    result = [self ehlo];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_EHLO];
        return;
    }

    [self.server determineSupportedAuthenticationSchemesFromEHLOResponse:self.lastResponse];

    if ((self.server.preferredAuthenticationScheme & TBSMTPAuthenticationScheme_NeedAuth) &&
        (self.server.supportedAuthenticationSchemes & TBSMTPAuthenticationScheme_NeedAuth)) {
        result = [self authenticate];
        if (!result) {

            self.error = [self errorForSMTPResponseType:TBSMTPResponseType_AUTH];
            return;
        }
    }

    result = [self mailFrom];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_MAIL];
        return;
    }

    result = [self rcptTo];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_RCPT];
        return;
    }

    result = [self data];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_DATA];
        return;
    }

    result = [self sendMessage];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_DATA_SEND];
        return;
    }

    result = [self quit];
    if (!result) {

        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_QUIT];
        return;
    }

    [self disconnect];
}


@end



@implementation TBSMTPTransporter (SMTPImplementation)


/**
 * @details first we wait for signal connectionDidEstablish, and the we read the response
 */
- (BOOL)connect {

    NSError *error = nil;
    BOOL result = [self.socket connectToHost:self.server.hostname onPort:(uint16_t)self.server.port withTimeout:kTransporterConnectTimeout error:&error];
    
    if (!result) {
        TBELogNetwork(@"connect not successfull");
        return NO;
    }
    else {
        if (self.server.TLSServer) {

            TBDLogNetwork(@"start TSL");
            [self.socket startTLS:@{
             (NSString *)kCFStreamSSLLevel						: (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
             ,(NSString *)kCFStreamSSLAllowsExpiredCertificates	: (NSNumber *)kCFBooleanTrue
             ,(NSString *)kCFStreamSSLAllowsExpiredRoots		: (NSNumber *)kCFBooleanTrue
             ,(NSString *)kCFStreamSSLAllowsAnyRoot				: (NSNumber *)kCFBooleanTrue
             ,(NSString *)kCFStreamSSLValidatesCertificateChain	: (NSNumber *)kCFBooleanFalse
             ,(NSString *)kCFStreamSSLPeerName					: self.server.hostname
             ,(NSString *)kCFStreamSSLIsServer					: (NSNumber *)kCFBooleanFalse
             }];
            TBDLogNetwork(@"did TSL");
        }
    }

    if (0 != dispatch_semaphore_wait(_connectionSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTransporterConnectTimeout * NSEC_PER_SEC)))) {
        TBELogNetwork(@"connect timed out");
        return NO;
    }
//	[self.socket readDataWithTimeout:kTransporterProtocolTimeout buffer:self.receivedData bufferOffset:self.receivedData.length maxLength:kTransporterMaxBufferLength tag:TBSMTPResponseType_CONNECTION_ESTABLISHMENT];
//
//	dispatch_semaphore_wait(_readSemaphore, DISPATCH_TIME_FOREVER);
    [self receiveResponseWithTag:TBSMTPResponseType_CONNECTION_ESTABLISHMENT];

    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForCONNECTION_ESTABLISHED]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_CONNECTION_ESTABLISHMENT;

    return success;
}

- (void)disconnect {
    
    [self.socket setDelegate:nil delegateQueue:NULL];
    
    if (self.socket.isConnected)
        [self.socket disconnect];
}

- (BOOL)ehlo {

    [self sendRequestAndReceiveResponse:[TBSMTPRequest requestWithEHLO] withTag:TBSMTPResponseType_EHLO];

    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForEHLO]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_EHLO;
    
    return success;
}


/**
 @see http://tools.ietf.org/rfc/rfc2554.txt
 */
- (BOOL)authenticate {

    TBSMTPAuthenticationScheme scheme = self.server.preferredAuthenticationScheme;
    if (scheme == TBSMTPAuthenticationScheme_None)
        return YES;
    
    TBSMTPAuthenticator *authenticator = [TBSMTPAuthenticator authenticatorWithAuthenticationScheme:scheme andCredentialsProvider:self.server];
    
    // tell the server what authenticationScheme we want to use
    TBSMTPRequest *request = [TBSMTPRequest requestWithAUTHWithAuthenticationScheme:scheme];
    [self sendRequestAndReceiveResponse:request withTag:TBSMTPResponseType_AUTH];
    
    // receive the challange for authentication
    NSString *challange		= nil;
    NSString *response		= nil;
    
    // start round trips
    // [ fear and loathing in L.A. ]
    NSUInteger roundTripMax = authenticator.numberOfRoundTrips;
    for (NSUInteger ii = 1; ii <= roundTripMax; ii++) {
        
        // what the server did challange
        // tell the authenticator what we get
        challange = self.lastResponse.message;
        [authenticator authenticationChallengeString:challange forRoundTrip:ii];
        
        // ask the authenticator what to respond
        response = [authenticator authenticationResponseStringForRoundTrip:ii];
        TBSMTPRequest *request = [TBSMTPRequest requestWithAUTHForRoundTripsResponseString:response];
        [self sendRequestAndReceiveResponse:request withTag:(TBSMTPResponseType_AUTH | ii)];
    }
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForAUTH]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_AUTH;
    
    return success;
}

- (BOOL)mailFrom {
    
    [self sendRequestAndReceiveResponse:[TBSMTPRequest requestWithMAILFROM:self.message.fromSender.address] withTag:TBSMTPResponseType_MAIL];
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForMAIL]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_MAIL;
    
    return success;
}

- (BOOL)rcptTo {
    
    TBSMTPAddress *rcpt = [self.message.toRecipients objectAtIndex:0];
    [self sendRequestAndReceiveResponse:[TBSMTPRequest requestWithRCPTTO:rcpt.formattedSMTPAddress] withTag:TBSMTPResponseType_RCPT];
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForRCPT]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_RCPT;
    
    return success;
}

- (BOOL)data {
    
    [self sendRequestAndReceiveResponse:[TBSMTPRequest DATArequest] withTag:TBSMTPResponseType_DATA];
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForDATA]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_DATA;
    
    return success;
}

- (BOOL)sendMessage {
    
    [self sendRequestAndReceiveResponse:[TBSMTPRequest messageRequestWithMessage:self.message] withTag:TBSMTPResponseType_DATA_SEND];
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForMESSAGE]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_DATA_SEND;
    
    return success;
}

- (BOOL)quit {
    
    [self sendRequestAndReceiveResponse:[TBSMTPRequest QUITrequest] withTag:TBSMTPResponseType_QUIT];
    
    BOOL success = [self lastResponseHasSuccessCodeWithSuccessCodesArray:[TBSMTPResponse arrayOfSuccessReplayCodesForQUIT]];
    if (success)
        self.protocolProgressIndicator |= TBSMTPResponseType_QUIT;
    
    return success;
}


#pragma mark - send & receive

- (void)sendRequestAndReceiveResponse:(TBSMTPRequest *)request withTag:(NSUInteger)tag {
    
    [self sendRequst:request withTag:tag];
    
    while (self.lastResponse == nil)
        [self receiveResponseWithTag:tag];
}



- (void)sendRequst:(TBSMTPRequest *)request withTag:(NSUInteger)tag {
    
    self.lastResponse = nil;
    self.lastRequest = request;
    
    [self.socket writeData:request.rawData withTimeout:kTransporterProtocolTimeout tag:tag];
    dispatch_semaphore_wait(_writeSemaphore, DISPATCH_TIME_SMTP_TIMEOUT);
    
}

- (void)receiveResponseWithTag:(NSUInteger)tag {
    
    [self.socket readDataWithTimeout:kTransporterProtocolTimeout tag:tag];
    
    dispatch_semaphore_wait(_readSemaphore, DISPATCH_TIME_SMTP_TIMEOUT);
}

@end


@implementation TBSMTPTransporter (Validation)

- (BOOL)lastResponseHasSuccessCodeWithSuccessCodesArray:(NSArray *)successCodes {
    return [successCodes indexOfNumber:self.lastResponse.code] != NSNotFound;
}

- (NSError *)errorForSMTPResponseType:(TBSMTPResponseType)responseType {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    NSString *localizedDescription = [NSString stringWithFormat:@"Request [%@] fails with Response [%@]", self.lastRequest , self.lastResponse];
    
    [userInfo setValue:localizedDescription forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[NSNumber numberWithInteger:self.protocolProgressIndicator] forKey:@"protocolProgressIndicator"];
    [userInfo setValue:[NSNumber numberWithInteger:self.lastResponse.code] forKey:@"responseCode"];
    [userInfo setValue:self.lastResponse.description forKey:@"responseMessage"];
    [userInfo setValue:self.lastRequest.rawString.description forKey:@"requestMessage"];
    
    NSError *error = [[[NSError alloc] initWithDomain:@"TBSMTPTransporter" code:responseType userInfo:userInfo] autorelease];
    
    return error;
}

@end


@implementation TBSMTPTransporter (Delegates)


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    self.lastResponse = nil;
    self.lastRequest  = nil;
    
    TBDLogNetwork(@"didConnectToHost");
    
    dispatch_semaphore_signal(_connectionSemaphore);
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    
    TBDLogNetwork(@"socketDidDisconnect");
    
    if (error)
        TBWLogNetwork(@"%@", error);
    
    if (error.code == GCDAsyncSocketReadTimeoutError)
        dispatch_semaphore_signal(_readSemaphore);
    else if (error.code == GCDAsyncSocketConnectTimeoutError)
        dispatch_semaphore_signal(_connectionSemaphore);
    else if (error.code == GCDAsyncSocketWriteTimeoutError)
        dispatch_semaphore_signal(_writeSemaphore);
    else
        TBELogNetwork(@"error code %li not handled", (long)error.code);
}




- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    TBDLogNetwork(@"didWriteDataWithTag (%li)", tag);
    
    dispatch_semaphore_signal(_writeSemaphore);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    TBSMTPResponse *response = [TBSMTPResponse responseWithData:data andResponseType:(TBSMTPResponseType)tag];
    
    self.lastResponse = response;
    TBDLogNetwork(@"last Response: %@", self.lastResponse);
    
    dispatch_semaphore_signal(_readSemaphore);
}

@end





@implementation TBSMTPTransporterVerify : TBSMTPTransporter

- (id)initWithServer:(TBSMTPServer *)server {
    
    self = [super initWithMessage:nil andServer:server];
    if (self) {
        
    }
    return self;
}



#pragma mark - main behaviour

- (void)main {
    
    
    BOOL result = NO;
    
    _connectionQueue = dispatch_queue_create("transporterVerifyConnectionQueue", NULL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_connectionQueue];
    
    //
    //	connect
    //
    
    result = [self connect];
    if (!result) {
        
        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_CONNECTION_ESTABLISHMENT];
        return;
    }
    
    result = [self ehlo];
    if (!result) {
        
        self.error = [self errorForSMTPResponseType:TBSMTPResponseType_EHLO];
        return;
    }
    
    [self.server determineSupportedAuthenticationSchemesFromEHLOResponse:self.lastResponse];
    
    if (self.server.supportedAuthenticationSchemes & TBSMTPAuthenticationScheme_NeedAuth) {
        result = [self authenticate];
        if (!result) {
            
            self.error = [self errorForSMTPResponseType:TBSMTPResponseType_AUTH];
            return;
        }
    }
    else {
        self.error = [self errorForSMTPNoAuthenticationSupported];
    }
    
    [self disconnect];
}


#pragma mark - Error

- (NSError *)errorForSMTPNoAuthenticationSupported {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    NSString *localizedDescription = [NSString stringWithFormat:@"Request [%@] fails with Response [%@]", self.lastRequest , self.lastResponse];
    
    [userInfo setValue:localizedDescription forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[NSNumber numberWithInteger:self.protocolProgressIndicator] forKey:@"protocolProgressIndicator"];
    
    NSError *error = [[[NSError alloc] initWithDomain:@"TBSMTPTransporterVerify" code:0 userInfo:userInfo] autorelease];
    
    return error;
}

@end



#undef kTransporterConnectTimeout
#undef kTransporterProtocolTimeout

#undef DISPATCH_TIME_SMTP_TIMEOUT



