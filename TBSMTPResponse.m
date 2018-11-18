//
//  TBSMTPResponse.m
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import "TBSMTPResponse.h"
#import "TBSMTPConstants.h"


@interface NSString (CrossPlatformRegexExtensions)
- (NSRange)rangeOfRegexPattern:(NSString *)pattern;
- (NSString *)firstCaptureGroupOfRegexPattern:(NSString *)pattern;
- (NSArray *)captureGroupsOfRegexPattern:(NSString *)pattern;
@end


@implementation NSString (CrossPlatformRegexExtensions)

- (NSRange)rangeOfRegexPattern:(NSString *)pattern {
    NSRange matchRange = NSMakeRange(NSNotFound, 0);
    
#if NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS
    RKRegex *regEx = [RKRegex regexWithRegexString:pattern options:RKCompileCaseless|RKCompileMultiline];
    if (regEx)
        matchRange = [self rangeOfRegex:regEx];
#else
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:NULL];
    if (regEx)
        matchRange = [regEx rangeOfFirstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
#endif
    
    return matchRange;
}

- (NSString *)firstCaptureGroupOfRegexPattern:(NSString *)pattern {
    return [[self captureGroupsOfRegexPattern:pattern] objectAtIndex:0];
}

- (NSArray *)captureGroupsOfRegexPattern:(NSString *)pattern {
    NSMutableArray *values = [[@[] mutableCopy] autorelease];
    
    if (pattern.length > 0) {
        
#if NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS
        RKRegex *regEx = [RKRegex regexWithRegexString:pattern options:RKCompileCaseless|RKCompileMultiline];
        if (regEx) {
            for (NSInteger i = 0; i < regEx.captureCount - 1; i++) {
                NSString *reference	= [NSString stringWithFormat:@"$%ld",(long)i+1];
                NSString *value		= nil;
                if ([self getCapturesWithRegexAndReferences:regEx, reference, &value, nil] && value != nil)
                    [values addObject:value];
            }
        }
#else
        NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:NULL];
        if (regEx) {
            for (NSUInteger i = 0; i < regEx.numberOfCaptureGroups; i++) {
                NSString *reference	= [NSString stringWithFormat:@"$%lu",(long)i+1];
                NSString *value		= nil;
                if ((value = [regEx stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:reference]))
                    [values addObject:value];
            }
        }
#endif
    }
    
    return values.count > 0 ? values : nil;
}

@end


#pragma mark -


@interface TBSMTPResponse ()

@property (assign) TBSMTPResponseType		responseType;
@property (assign) NSInteger			code;
@property (readwrite, retain) NSString	*message;
@property (readwrite, retain) NSData	*responseData;
@property (assign) NSStringEncoding		usedEncoding;

@end


@implementation TBSMTPResponse

@synthesize responseType = _responseType;
@synthesize code = _code;
@synthesize message = _message;
@synthesize responseData = _responseData;
@synthesize usedEncoding = _usedEncoding;


+ (id)responseWithData:(NSData *)responseData andResponseType:(TBSMTPResponseType)responseType {

    if (!responseData)
        return nil;


    // try to determine encoding

//	DLog(@"didReadData  CString    %@",  [NSString stringWithUTF8String:responseData.bytes]);
//	DLog(@"didReadData  UTF8String %@",  [NSString stringWithUTF8String:responseData.bytes]);
//
//	DLog(@"didReadData  CP1252     %@",  [NSString stringWithCString:responseData.bytes encoding:NSWindowsCP1252StringEncoding]);
//	DLog(@"didReadData  ASCII      %@",  [NSString stringWithCString:responseData.bytes encoding:NSASCIIStringEncoding]);
//	DLog(@"didReadData  LATIN1     %@",  [NSString stringWithCString:responseData.bytes encoding:NSISOLatin1StringEncoding]);
//	DLog(@"didReadData  UTF8       %@",  [NSString stringWithCString:responseData.bytes encoding:NSUTF8StringEncoding]);
//	DLog(@"didReadData  UNICODE    %@",  [NSString stringWithCString:responseData.bytes encoding:NSUnicodeStringEncoding]);


    NSString *responseString = nil;
    NSStringEncoding usedEncoding = 0;


    // NSWindowsCP1252StringEncoding
    responseString = [NSString stringWithCString:responseData.bytes encoding:NSWindowsCP1252StringEncoding];
    usedEncoding = NSWindowsCP1252StringEncoding;

    // NSASCIIStringEncoding
    if (!responseString) {
        responseString = [NSString stringWithCString:responseData.bytes encoding:NSASCIIStringEncoding];
        usedEncoding = NSASCIIStringEncoding;
    }

    // NSISOLatin1StringEncoding
    if (!responseString) {
        responseString = [NSString stringWithCString:responseData.bytes encoding:NSISOLatin1StringEncoding];
        usedEncoding = NSISOLatin1StringEncoding;
    }

    // NSUTF8StringEncoding
    if (!responseString) {
        responseString = [NSString stringWithCString:responseData.bytes encoding:NSUTF8StringEncoding];
        usedEncoding = NSUTF8StringEncoding;
    }

    // NSUnicodeStringEncoding
    if (!responseString) {
        responseString = [NSString stringWithCString:responseData.bytes encoding:NSUnicodeStringEncoding];
        usedEncoding = NSUnicodeStringEncoding;
    }

    if (!responseString) {
        usedEncoding = 0;
    }

//	DLog(@"usedEncoding: %u", usedEncoding);


    if (!responseString)
        return nil;

    //const RKCompileOption options = RKCompileMultiline;
    //RKRegex *regex = [RKRegex regexWithRegexString:@"(?<CODE>^\\d{3}) (?<MESSAGE>[^\\r\\n]*)" options:options];
    
    NSString *regex = [NSString stringWithFormat:@"(\\d{3}) ([^\\r\\n]*)"];

    NSRange matchRange = [responseString rangeOfRegexPattern:regex];

    if (matchRange.location == NSNotFound)
        return nil;

    NSString *subString = [responseString substringWithRange:matchRange];
    
    NSArray *groups = [subString captureGroupsOfRegexPattern:regex];
    NSString *code		= groups.count > 0 ? [groups objectAtIndex:0] : nil;
    NSString *message	= groups.count > 1 ? [groups objectAtIndex:1] : nil;
    
    if (!code)
        return nil;
    
    TBSMTPResponse *response	= [[[TBSMTPResponse alloc] init] autorelease];
    response.responseData		= [[responseData copy] autorelease];
    response.message			= [[message copy] autorelease];
    response.code				= code.integerValue;
    response.responseType		= responseType;
    response.usedEncoding		= usedEncoding;

    return response;
}


- (void)dealloc {
    [_message release], _message = nil;
    [_responseData release], _responseData = nil;

    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[TBSMTPResponse code: %li | type: %i | encoding: %li | message: %@]\n", (long)self.code, self.responseType, self.usedEncoding, self.message];
}

@end


@implementation TBSMTPResponse (Parsing)

+ (TBSMTPAuthenticationScheme)authenticationSchemeForAuthCommandString:(NSString *)authenticationString {

    if ([authenticationString isEqualToString:kAuthenticationType_LoginString])
        return TBSMTPAuthenticationScheme_Login;

    else if ([authenticationString isEqualToString:kAuthenticationType_CRAM_MD5String])
        return TBSMTPAuthenticationScheme_CRAM_MD5;

    else if ([authenticationString isEqualToString:kAuthenticationType_DIGESTMD5String])
        return TBSMTPAuthenticationScheme_DIGEST_MD5;

    else if ([authenticationString isEqualToString:kAuthenticationType_PlainString])
        return TBSMTPAuthenticationScheme_Plain;

    else
        return TBSMTPAuthenticationScheme_None;
}


@end


@implementation TBSMTPResponse (Validation)


#pragma mark CONNECTION ESTABLISHED

+ (NSArray *)arrayOfSuccessReplayCodesForCONNECTION_ESTABLISHED {
    return @[ @220 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForCONNECTION_ESTABLISHED {
    return @[ @554 ];
}

#pragma mark EHLO

+ (NSArray *)arrayOfSuccessReplayCodesForEHLO {
    return @[ @250 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForEHLO {
    return @[ @504, @550 ];
}

#pragma mark MAIL

+ (NSArray *)arrayOfSuccessReplayCodesForMAIL {
    return @[ @250 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForMAIL {
    return @[ @552, @451, @452, @550, @553, @503 ];
}


#pragma mark RCPT

+ (NSArray *)arrayOfSuccessReplayCodesForRCPT {
    return @[ @250, @251 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForRCPT {
    return @[ @550, @551, @552, @553, @450, @451, @452, @503, @550 ];
}

#pragma mark DATA

+ (NSArray *)arrayOfSuccessReplayCodesForDATA {
    return @[ @354 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForDATA {
    return @[ @451, @554, @503 ];
}

#pragma mark MESSAGE (DATA)
// this si the second part of DATA

+ (NSArray *)arrayOfSuccessReplayCodesForMESSAGE {
    return @[ @250 ];
}

+ (NSArray *)arrayOfErrorReplayCodesForMESSAGE {
    return @[ @552, @554, @451, @452 ];
}


#pragma mark RSET

+ (NSArray *)arrayOfSuccessReplayCodesForRSET {
    return @[ @250 ];
}

#pragma mark QUIT

+ (NSArray *)arrayOfSuccessReplayCodesForQUIT {
    return @[ @221 ];
}


#pragma mark AUTH

+ (NSArray *)arrayOfSuccessReplayCodesForAUTH {
    return @[ @235, @334 ];
}


/**
 RFC 2554 §6
 6. Error Codes

 The following error codes may be used to indicate various conditions
 as described.

 432 A password transition is needed

 This response to the AUTH command indicates that the user needs to
 transition to the selected authentication mechanism.  This typically
 done by authenticating once using the PLAIN authentication mechanism.

 534 Authentication mechanism is too weak

 This response to the AUTH command indicates that the selected
 authentication mechanism is weaker than server policy permits for
 that user.

 538 Encryption required for requested authentication mechanism

 This response to the AUTH command indicates that the selected
 authentication mechanism may only be used when the underlying SMTP
 connection is encrypted.

 454 Temporary authentication failure

 This response to the AUTH command indicates that the authentication
 failed due to a temporary server failure.

 530 Authentication required

 This response may be returned by any command other than AUTH, EHLO,
 HELO, NOOP, RSET, or QUIT.  It indicates that server policy requires
 authentication in order to perform the requested action.



 @see http://tools.ietf.org/rfc/rfc2554
 */
+ (NSArray *)arrayOfErrorReplayCodesForAUTH {
    return @[ @432, @534, @452 ];
}

@end