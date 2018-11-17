//
//  TBSMTPAuthenticationCredentialsProvider.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 25.09.13.
//

/**
 The SMTPAuthenticator will ask the credentialsProvider for username and password.

 */
@protocol TBSMTPAuthenticatorCredentialsProvider <NSObject>

@property (readonly) NSString *username;
@property (readonly) NSString *password;

@end
