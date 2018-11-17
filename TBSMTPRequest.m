//
//  TBSMTPRequest.m
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import "TBSMTPRequest.h"
#import "TBSMTPClient.h"

@implementation TBSMTPRequest


@synthesize rawString = _rawString;

- (id)init
{
    self = [super init];
    if (self) {
        _rawString = nil;
    }
    return self;
}

- (void)dealloc {

	[_rawString release]; _rawString = nil;
	[super dealloc];
}


- (NSData *)rawData {
//	return [NSData dataWithBytes:self.rawString.UTF8String length:self.rawString.length];
	return [self.rawString dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)authCommandStringForAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationType {

	NSString *result = nil;

	switch (authenticationType) {
		case TBSMTPAuthenticationScheme_Plain:
			result = kAuthenticationType_PlainString;
			break;

		case TBSMTPAuthenticationScheme_Login:
			result = kAuthenticationType_LoginString;
			break;

		case TBSMTPAuthenticationScheme_CRAM_MD5:
			result = kAuthenticationType_CRAM_MD5String;
			break;

		case TBSMTPAuthenticationScheme_DIGEST_MD5:
			result = kAuthenticationType_DIGESTMD5String;
			break;

		case TBSMTPAuthenticationScheme_None:
			// fall through
		case TBSMTPAuthenticationScheme_UNKNOWN:
			// fall through
		default:
			// PLAIN as fallback
			result = kAuthenticationType_PlainString;
			break;
	}

	return [[result retain] autorelease];
}


#pragma mark EHLO

+ (id)requestWithEHLO {
	return [TBSMTPRequest requestWithEHLOAndGreeting:@""];
}

+ (id)requestWithEHLOAndGreeting:(NSString *)greeting {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"EHLO %@%@", greeting, kRequestEOL];

	return [request autorelease];
}

#pragma mark AUTH

+ (id)requestWithAUTHWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	NSString *authenticationSchemeString = [TBSMTPRequest authCommandStringForAuthenticationScheme:authenticationScheme];
	request.rawString = [NSString stringWithFormat:@"AUTH %@%@", authenticationSchemeString, kRequestEOL];

	return [request autorelease];
}

+ (id)requestWithAUTHForRoundTripsResponseString:(NSString *)response {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"%@%@", response, kRequestEOL];

	return [request autorelease];
}

#pragma mark MAIL

+ (id)requestWithMAILFROM:(NSString *)from {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"MAIL FROM: %@%@", from, kRequestEOL];

	return [request autorelease];
}

#pragma mark RCPT

+ (id)requestWithRCPTTO:(NSString *)to {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"RCPT TO: %@%@", to, kRequestEOL];

	return [request autorelease];
}

#pragma mark DATA

+ (id)DATArequest {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"DATA%@", kRequestEOL];

	return [request autorelease];
}

+ (id)messageRequestWithMessage:(TBSMTPMessage *)message {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"%@%@", message.formattedIMFMessage, kRequestEOM];

	return [request autorelease];
}

#pragma mark QUIT

+ (id)QUITrequest {

	TBSMTPRequest *request = [[TBSMTPRequest alloc] init];
	request.rawString = [NSString stringWithFormat:@"QUIT%@", kRequestEOL];

	return [request autorelease];
}


#pragma mark - Override

- (NSString *)description {
	return self.rawString ? self.rawString : @"";
}

@end
