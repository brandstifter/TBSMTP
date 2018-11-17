//
//  TBSMTPResponse.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import <Foundation/Foundation.h>

#import "TBSMTPRequest.h"
#import "TBSMTPAuthenticator.h"


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


typedef enum {
	TBSMTPResponseType_NOT_SPECIFIED					= 0,

	TBSMTPResponseType_CONNECTION_ESTABLISHMENT		= (1 << 0),
	TBSMTPResponseType_EHLO							= (1 << 1),
	TBSMTPResponseType_HELO							= (1 << 2),
	TBSMTPResponseType_AUTH							= (1 << 3),
	TBSMTPResponseType_MAIL							= (1 << 4),
	TBSMTPResponseType_RCPT							= (1 << 5),
	TBSMTPResponseType_DATA							= (1 << 6),
	TBSMTPResponseType_RSET							= (1 << 7),
	TBSMTPResponseType_VRFY							= (1 << 8),
	TBSMTPResponseType_EXPN							= (1 << 9),
	TBSMTPResponseType_HELP							= (1 << 10),
	TBSMTPResponseType_NOOP							= (1 << 11),
	TBSMTPResponseType_QUIT							= (1 << 12),


	TBSMTPResponseType_DATA_SEND						= TBSMTPResponseType_DATA | (1 << 16),	// subtag for DATA

	// space for further constants

	TBSMTPResponseType_AUTH_RT1						= TBSMTPResponseType_AUTH | (1 << 24),	// subtag for Challange/Response RoundTrip

	// space for further constants

} TBSMTPResponseType;

/**
 @discussion The class is well documented in TBSMTPResponseTests class
 
 @see TBSMTPResponseTests
 */
@interface TBSMTPResponse : NSObject {
	TBSMTPResponseType	_responseType;
	NSInteger			_code;
	NSString			*_message;
	NSData				*_responseData;
	NSStringEncoding	_usedEncoding;
}

@property (readonly, assign) TBSMTPResponseType	responseType;		/**< Indicate the type this response belongs to */

/**
 The parsed response code from received responseData

 @see resonseData
 */
@property (readonly, assign) NSInteger			code;

/**
 The parsed response message from received responseData
 
 @see responseData
 */
@property (readonly, retain) NSString			*message;

@property (readonly, retain) NSData				*responseData;		/**< The raw data received from the server */

@property (readonly, assign) NSStringEncoding	usedEncoding;		/**< The used NSStringEncoding determined to understand the responseData correctly */


/**
 
 @return Return an valid SMTP server response or nil if responseString is an
	incomplete or invalid server response
 */
+ (id)responseWithData:(NSData *)responseData andResponseType:(TBSMTPResponseType)responseType;

@end


@interface TBSMTPResponse (Parsing)

+ (TBSMTPAuthenticationScheme)authenticationSchemeForAuthCommandString:(NSString *)authenticationString;

@end

/**
 Validation according to RFC 2821 §4.3.2 Command-Reply Sequences and 
 RFC 2554 AUTH 
 
 excerp:
 
 CONNECTION ESTABLISHMENT
 S: 220
 E: 554
 EHLO or HELO
 S: 250
 E: 504, 550
 MAIL
 S: 250
 E: 552, 451, 452, 550, 553, 503
 RCPT
 S: 250, 251 (but see section 3.4 for discussion of 251 and 551)
 E: 550, 551, 552, 553, 450, 451, 452, 503, 550
 DATA
 I: 354 -> data ->	S: 250
					E: 552, 554, 451, 452
 E: 451, 554, 503
 RSET
 S: 250
 VRFY
 S: 250, 251, 252
 E: 550, 551, 553, 502, 504
 EXPN
 S: 250, 252
 E: 550, 500, 502, 504
 HELP
 S: 211, 214
 E: 502, 504
 NOOP
 S: 250
 QUIT
 S: 221

 @see http://tools.ietf.org/html/rfc2821 [page 48]
 @see http://tools.ietf.org/rfc/rfc2554.txt
 */
@interface TBSMTPResponse (Validation)

#pragma mark CONNECTION ESTABLISHED

+ (NSArray *)arrayOfSuccessReplayCodesForCONNECTION_ESTABLISHED;
+ (NSArray *)arrayOfErrorReplayCodesForCONNECTION_ESTABLISHED;

#pragma mark EHLO

+ (NSArray *)arrayOfSuccessReplayCodesForEHLO;
+ (NSArray *)arrayOfErrorReplayCodesForEHLO;

#pragma mark MAIL

+ (NSArray *)arrayOfSuccessReplayCodesForMAIL;
+ (NSArray *)arrayOfErrorReplayCodesForMAIL;

#pragma mark RCPT

+ (NSArray *)arrayOfSuccessReplayCodesForRCPT;
+ (NSArray *)arrayOfErrorReplayCodesForRCPT;

#pragma mark DATA

+ (NSArray *)arrayOfSuccessReplayCodesForDATA;
+ (NSArray *)arrayOfErrorReplayCodesForDATA;

#pragma mark MESSAGE (DATA)
// this si the second part of DATA

+ (NSArray *)arrayOfSuccessReplayCodesForMESSAGE;
+ (NSArray *)arrayOfErrorReplayCodesForMESSAGE;


#pragma mark RSET

+ (NSArray *)arrayOfSuccessReplayCodesForRSET;

#pragma mark QUIT

+ (NSArray *)arrayOfSuccessReplayCodesForQUIT;


#pragma mark AUTH

+ (NSArray *)arrayOfSuccessReplayCodesForAUTH;


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
+ (NSArray *)arrayOfErrorReplayCodesForAUTH;

@end