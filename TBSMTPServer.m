//
//  TBSMTPServer.m
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 11.09.13.
//

#import "TBSMTPServer.h"
#import "TBSMTPResponse.h"
#import "TBSMTPConstants.h"
#import "TBSMTPTransporter.h"
#import "TBSMTPAuthenticator.h"


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


@interface TBSMTPServer ()

@property (assign, readwrite) NSInteger supportedAuthenticationSchemes;

@end


@implementation TBSMTPServer

@synthesize hostname = _hostname;
@synthesize port = _port;
@synthesize TLSServer = _TLSServer;
@synthesize username = _username;
@synthesize password = _password;
@synthesize supportedAuthenticationSchemes = _supportedAuthenticationSchemes;
@synthesize preferredAuthenticationScheme = _preferredAuthenticationScheme;



#pragma mark - Object Lifecycle


- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port {
    return [self initWithHostname:hostname andPort:port andPreferedAuthenticationScheme:TBSMTPAuthenticationScheme_None andUsername:nil andPassword:nil];
}

- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port andPreferedAuthenticationScheme:(TBSMTPAuthenticationScheme)preferredAuthenticationScheme andUsername:(NSString *)username andPassword:(NSString *)password {
    return [self initWithHostname:hostname andPort:port andPreferedAuthenticationScheme:preferredAuthenticationScheme andUsername:username andPassword:password isTLSServer:NO];
}

- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port andPreferedAuthenticationScheme:(TBSMTPAuthenticationScheme)preferredAuthenticationScheme andUsername:(NSString *)username andPassword:(NSString *)password isTLSServer:(BOOL)isTLSServer {
    self = [super init];
    if (self) {
        _hostname	= [hostname copy];
        _username	= [username copy];
        _password	= [password copy];
        
        _port							= port;
        _preferredAuthenticationScheme	= preferredAuthenticationScheme;
        _TLSServer						= isTLSServer;
        
        if (!(self.hostname.length > 0 && self.port > 0)) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    self.hostname	= nil;
    self.username	= nil;
    self.password	= nil;
    
    [super dealloc];
}


#pragma mark -

- (void)determineSupportedAuthenticationSchemesFromEHLOResponse:(TBSMTPResponse *)response {

    self.supportedAuthenticationSchemes = TBSMTPAuthenticationScheme_UNKNOWN;

    if (!response.responseData || response.responseType != TBSMTPResponseType_EHLO)
        // cannot decide yet
        return;

    NSString *searchString = [NSString stringWithUTF8String:response.responseData.bytes];

    //const RKCompileOption options = RKCompileMultiline;
    //RKRegex *regex = [RKRegex regexWithRegexString:@"(250-AUTH (?<AUTHTYPES>[^\\r\\n]*))" options:options];
    
    NSString *regex = [NSString stringWithFormat:@"(250[\\s-]AUTH ([^\\r\\n]*))"];
    
    NSRange matchRange = [searchString rangeOfRegexPattern:regex];
    
    if (matchRange.location == NSNotFound) {
        // we assume none here
        self.supportedAuthenticationSchemes = TBSMTPAuthenticationScheme_None;
        return;
    }
    
    NSString *subString = [searchString substringWithRange:matchRange];
    
    NSArray *groups = [subString captureGroupsOfRegexPattern:regex];
    NSString *authTypesString = groups.count > 1 ? [groups objectAtIndex:1] : nil;
    
    NSArray *authTypes = [authTypesString componentsSeparatedByString:@" "];
    
    NSInteger result = 0;
    for (NSString *authType in authTypes)
        result |= [TBSMTPResponse authenticationSchemeForAuthCommandString:authType];

    self.supportedAuthenticationSchemes = result;
}

@end


