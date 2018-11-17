//
//  TBSMTPAuthenticator.m
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 18.09.13.
//

#import "TBSMTPAuthenticator.h"
#import "NSString+Coding.h"
#import "NSString+Hash.h"

#define kAbstractMethodException		[NSException exceptionWithName:@"abstract method" reason:@"abstract method" userInfo:nil]


@interface TBSMTPAuthenticator ()

- (id)initWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme andCredentialsProvider:(id<TBSMTPAuthenticatorCredentialsProvider>)credentialsProvider;

@end


/**
 TBSMTPAuthenticatorCRAMMD5

 Implementation of the CRAM-MD5 authentication. The mechanism is specified in
 RFC 4954 and RFC 2195.


 @see http://tools.ietf.org/html/rfc2195 [Page 2]
 @see http://tools.ietf.org/html/rfc4954

 @example Next follows a formal and a real example

 transaction (formal)

 C: AUTH CRAM-MD5
 S: 334 BASE64(NONCE)
 C: BASE64(USERNAME, " ", MD5((SECRET XOR opad),MD5((SECRET XOR ipad), NONCE)))
 S: 235 Authentication succeeded

 ----

 Where NONCE is the once time challenge string, USERNAME is the username you
 are tryng to authenticate, SECRET is the shared secret ("password"),
 opad is 0x5C, and ipad is 0x36.


 transaction (real example)

 C: AUTH CRAM-MD5
 S: 334 PDQ1MDMuMTIyMzU1Nzg2MkBtYWlsMDEuZXhhbXBsZS5jb20+
 C: dXNlckBleGFtcGxlLmNvbSA4YjdjODA5YzQ0NTNjZTVhYTA5N2VhNWM4OTlmNGY4Nw==
 S: 235 Authentication succeeded

 ----


 */
@interface TBSMTPAuthenticatorCRAMMD5 : TBSMTPAuthenticator <TBSMTPAuthenticatorInterface> {

	NSString *_challangeStringOfRoundTrip1;
}

/**
 Reference to the challange of round trip 1
 */
@property (copy) NSString *challangeStringOfRoundTrip1;


/**
 retrieve the BASE64(NONCE)

 @param challengeData The BASE64(NONCE)
 @param roundTrip The current roundTrip, the only valid number is 1
 */
- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip;

/**
 calculates the string for authentication response for round trip 1.

 @param roundTrip the round trip number, the only valid number is 1.
 @return The authention response for the server
 */
- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip;

@end



/**
 TBSMTPAuthenticatorCRAMMD5
 
 Implementation of the CRAM-MD5 authentication. The mechanism is specified in
 RFC 4954 and RFC 2195.
 
 
 @see http://tools.ietf.org/html/rfc2195 [Page 2]
 @see http://tools.ietf.org/html/rfc4954
 
 @example Next follows a formal and a real example
 
 transaction (formal)
 
 C: AUTH CRAM-MD5
 S: 334 BASE64(NONCE)
 C: BASE64(USERNAME, " ", MD5((SECRET XOR opad),MD5((SECRET XOR ipad), NONCE)))
 S: 235 Authentication succeeded
 
 ----
 
 Where NONCE is the once time challenge string, USERNAME is the username you
 are tryng to authenticate, SECRET is the shared secret ("password"),
 opad is 0x5C, and ipad is 0x36.
 
 
 transaction (real example)
 
 C: AUTH CRAM-MD5
 S: 334 PDQ1MDMuMTIyMzU1Nzg2MkBtYWlsMDEuZXhhbXBsZS5jb20+
 C: dXNlckBleGFtcGxlLmNvbSA4YjdjODA5YzQ0NTNjZTVhYTA5N2VhNWM4OTlmNGY4Nw==
 S: 235 Authentication succeeded
 
 ----
 
 
 */
@interface TBSMTPAuthenticatorLOGIN : TBSMTPAuthenticator <TBSMTPAuthenticatorInterface> {
    
	NSString *_challangeStringOfRoundTrip1;
    NSString *_challangeStringOfRoundTrip2;
}


@property (copy) NSString *challangeStringOfRoundTrip1;     /**< Reference to the challange of round trip 1 */
@property (copy) NSString *challangeStringOfRoundTrip2;     /**< Reference to the challange of round trip 2 */

/**
 retrieve the BASE64(NONCE)
 
 @param challengeData The BASE64(NONCE)
 @param roundTrip The current roundTrip, the only valid number is 1
 */
- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip;

/**
 calculates the string for authentication response for round trip 1.
 
 @param roundTrip the round trip number, the only valid number is 1.
 @return The authention response for the server
 */
- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip;

@end









@implementation TBSMTPAuthenticator

@dynamic numberOfRoundTrips;
@synthesize authenticationScheme = _authenticationScheme;
@synthesize credentialsProvider = _credentialsProvider;


#pragma mark - Object LifeCycle

- (id)initWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme andCredentialsProvider:(id<TBSMTPAuthenticatorCredentialsProvider>)credentialsProvider {

	self = [super init];
    if (self) {
        _authenticationScheme = authenticationScheme;
		_credentialsProvider = credentialsProvider;
    }
    return self;
}


+ (id)authenticatorWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme andCredentialsProvider:(id<TBSMTPAuthenticatorCredentialsProvider>)credentialsProvider {

	switch (authenticationScheme) {
		case TBSMTPAuthenticationScheme_CRAM_MD5: {

			return [[[TBSMTPAuthenticatorCRAMMD5 alloc] initWithAuthenticationScheme:authenticationScheme andCredentialsProvider:credentialsProvider] autorelease];
		}
			break;
            
        case TBSMTPAuthenticationScheme_Login: {
            return [[[TBSMTPAuthenticatorLOGIN alloc] initWithAuthenticationScheme:authenticationScheme andCredentialsProvider:credentialsProvider] autorelease];
            
        }
            break;

		case TBSMTPAuthenticationScheme_None:
			// fall through
		default:
			return nil;
			break;
	}

}


#pragma mark - Methods must have been overriden !

- (NSUInteger)numberOfRoundTrips {

	@throw(kAbstractMethodException); // should never happen
}

- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip {

	@throw(kAbstractMethodException); // should never happen
}

- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip {

	@throw(kAbstractMethodException); // should never happen
}

@end






@implementation TBSMTPAuthenticatorCRAMMD5

@synthesize challangeStringOfRoundTrip1 = _challangeStringOfRoundTrip1;


- (void)dealloc {
	[_challangeStringOfRoundTrip1 release]; _challangeStringOfRoundTrip1 = nil;
	[super dealloc];
}

- (NSUInteger)numberOfRoundTrips {
	return 1;
}


- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip {

	self.challangeStringOfRoundTrip1 = (roundTrip == 1) ? challengeString : nil;
}

/**
 provide BASE64(USERNAME, " ", MD5((SECRET XOR opad),MD5((SECRET XOR ipad), NONCE)))

 @return
 */
- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip {

	NSString *username = self.credentialsProvider.username ? self.credentialsProvider.username : @"";
	NSString *password = self.credentialsProvider.password ? self.credentialsProvider.password : @"";
	NSString *challange = self.challangeStringOfRoundTrip1;

	/*
	 perl script http://www.tjd.phlegethon.org/software/cram-md5.pl

	 my ($challenge, $username, $password) = @ARGV;
	 my $response = hmac_md5_hex(decode_base64($challenge), $password);
	 print encode_base64("$username $response");
	 */


	NSString *step1 = [[challange base64DecodedString] hmacMD5EncryptedStringWithSecret:password];
	NSString *step2 = [NSString stringWithFormat:@"%@ %@", username, step1];
	NSString *step3 = [step2 base64EncodedString];

	return step3;
}

@end


@implementation TBSMTPAuthenticatorLOGIN

- (void)dealloc {
	[_challangeStringOfRoundTrip1 release]; _challangeStringOfRoundTrip1 = nil;
	[super dealloc];
}

- (NSUInteger)numberOfRoundTrips {
	return 2;
}


- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip {
    // we don't need to store informations
}


- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip {
    
    if (roundTrip == 1)
        return [self.credentialsProvider.username base64EncodedString];
    else if (roundTrip == 2)
        return [self.credentialsProvider.password base64EncodedString];
    else
        return @"";
}

@end


#undef kAbstractMethodException
