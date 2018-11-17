//
//  TBSMTPServer.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 11.09.13.
//

#import <Foundation/Foundation.h>

#import "TBSMTPConstants.h"
#import "TBSMTPAuthenticationCredentialsProvider.h"


#if TARGET_OS_IPHONE
	#if		__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_0
		#define NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS	1

	#elif	__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
		#define NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS	0

	#else
		#define NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS	0
	#endif

#else
	#if		MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_7
		#define NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS	1

	#else
		#define NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS	0
	#endif
#endif


#if NEEDS_REGEXKIT_FOR_REGULAR_EXPRESSIONS
	#import <RegexKit/RegexKit.h>
#else
	#import <Foundation/NSRegularExpression.h>
#endif


@class TBSMTPResponse;


/**
 This class holds informations for the TBSMTPTransporter to connect to a server.
 
 @see TBSMTPTransporter
 */
@interface TBSMTPServer : NSObject {

	NSString *_hostname;
	NSInteger _port;
	BOOL _TLSServer;
	NSString *_username;
	NSString *_password;
	NSInteger _supportedAuthenticationSchemes;
	TBSMTPAuthenticationScheme _preferredAuthenticationScheme;


}

@property (copy)	NSString *hostname;						/**< The hostname of the server */
@property (assign)	NSInteger port;							/**< The port to connect to */
@property (assign, getter=_isTLSServer) BOOL TLSServer;		/**, The server should be contacted via a TLS connection */
@property (copy)	NSString *username;						/**, The username to authenticate against the server */
@property (copy)	NSString *password;						/** The password to authenticate against the server */
@property (readonly) NSInteger supportedAuthenticationSchemes;	/** Bitmask for authentication schemes supported by this server */


- (id)init __attribute__((unavailable("init not available, use - (id)initWithMessage:(TBSMTPMessage *)message andSesrver:(TBSMTPServer *)server;")));

/**
 @param hostname
 @param port
 */
- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port;

/**
 @param hostname 
 @param port
 @param preferedAuthenticationScheme
 @param username
 @param password
 */
- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port andPreferedAuthenticationScheme:(TBSMTPAuthenticationScheme)preferedAuthenticationScheme andUsername:(NSString *)username andPassword:(NSString *)password;


/**
 @param hostname
 @param port
 @param preferedAuthenticationScheme
 @param username
 @param password
 */
- (id)initWithHostname:(NSString *)hostname andPort:(NSInteger)port andPreferedAuthenticationScheme:(TBSMTPAuthenticationScheme)preferedAuthenticationScheme andUsername:(NSString *)username andPassword:(NSString *)password isTLSServer:(BOOL)isTLSServer;


/**
 The authentication scheme used to connect to the server.

 @discussion if the server does not support this authentication scheme, 
 TBSMTPAuthenticationScheme_None is used. 
 
 @see TBSMTPAuthenticationScheme
 */
@property (assign) TBSMTPAuthenticationScheme preferredAuthenticationScheme;


/**
 Determines the supported authentication schemes by parsing the EHLO response 
 from the server.

 @discussion  If the response data is invalid or the response is not an
 EHLO response, the supportedAuthenticationSchemes proterty is set to 
 TBSMTPAuthenticationScheme_UNKNOWN.
 
 If the server provide no AUTH information or authentications which are not 
 recognized TBSMTPAuthenticationScheme_NONE is assumed.

 In any other case where the server provide information which are understood, 
 the supportedAuthenticationSchemes proterty is set to this schemes by bitmasking.

 @see supportedAuthenticationSchemes;

 @param response The response to parse. Must be a EHLOCommand
 */
- (void)determineSupportedAuthenticationSchemesFromEHLOResponse:(TBSMTPResponse *)response;

@end

@interface TBSMTPServer (Delegates) <TBSMTPAuthenticatorCredentialsProvider>
@end
