//
//  TBSMTPConstants.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 12.09.13.
//


NSString * const kAuthenticationType_PlainString;
NSString * const kAuthenticationType_LoginString;
NSString * const kAuthenticationType_CRAM_MD5String;
NSString * const kAuthenticationType_DIGESTMD5String;


NSString * const kRequestEOL;			/**< End Of Line seperator used in SMTP Protocol */
NSString * const kRequestEOM;			/**< End Of Message Delimiter used in SMTP Protocol */



/**
 The SMTP Authentication types a Transporter can handle

 @todo change to NS_ENUM if 10.6 support ends. Xcode code completion is better :)
 @todo: this is a list of authentication schemes of A1 (smtp.A1.net) and Swisscom (smtpauth.bluewin.ch)
 */
typedef enum {
	TBSMTPAuthenticationScheme_UNKNOWN			= -1,

	// group into secure / not-secure
	TBSMTPAuthenticationScheme_NeedAuth			= 1,


	// no auth
    TBSMTPAuthenticationScheme_None				= 0,

	// need auth
    TBSMTPAuthenticationScheme_Plain			= (1 << 3)	| TBSMTPAuthenticationScheme_NeedAuth,
    TBSMTPAuthenticationScheme_Login			= (1 << 4)	| TBSMTPAuthenticationScheme_NeedAuth,
    TBSMTPAuthenticationScheme_CRAM_MD5			= (1 << 5)	| TBSMTPAuthenticationScheme_NeedAuth,
	TBSMTPAuthenticationScheme_DIGEST_MD5		= (1 << 6)	| TBSMTPAuthenticationScheme_NeedAuth
} TBSMTPAuthenticationScheme;



