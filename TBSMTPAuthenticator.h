//
//  TBSMTPAuthenticator.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 18.09.13.
//

#import <Foundation/Foundation.h>

#import "TBSMTPConstants.h"
#import "TBSMTPAuthenticationCredentialsProvider.h"

@class TBSMTPResponse;



#define kOPad		((char)0x5C)
#define kIPad		((char)0x36)






@protocol TBSMTPAuthenticatorInterface <NSObject>

@property (readonly) NSUInteger numberOfRoundTrips;
@property (assign) TBSMTPAuthenticationScheme authenticationScheme;
@property (assign) id<TBSMTPAuthenticatorCredentialsProvider>credentialsProvider;



- (void)authenticationChallengeString:(NSString *)challengeString forRoundTrip:(NSUInteger)roundTrip;
- (NSString *)authenticationResponseStringForRoundTrip:(NSUInteger)roundTrip;


@end



/**

 TBSMTPAuthenticator (follows the Class Cluster Design Pattern)

 This is the "front class" of several authenticators. TBSMTPAuthenticator follows
 the "class cluster" design pattern and acts as *public interface* with a
 convenient shortcut. Instead of impementing alloc and init, we only implement
 the + (id)smtpAuthenticatorWithAuthenticationScheme:andCredentialsProvider:
 method, which is the *only* valid entry point for object instanciation.

 @details In order to get the shortcut work in a safe manner, the init method
 is not available.

 @see - (id)init
 @see - (id)smtpAuthenticatorWithAuthenticationScheme:andCredentialsProvider:


 */
@interface TBSMTPAuthenticator : NSObject <TBSMTPAuthenticatorInterface> {

    TBSMTPAuthenticationScheme _authenticatinScheme;
    id<TBSMTPAuthenticatorCredentialsProvider> _credentialsProvider;
    TBSMTPAuthenticationScheme _authenticationScheme;
}

@property (readonly) NSUInteger numberOfRoundTrips;
@property (assign) TBSMTPAuthenticationScheme authenticationScheme;
@property (assign) id<TBSMTPAuthenticatorCredentialsProvider>credentialsProvider;



- (id)init __attribute__((unavailable("init not available, use + (id)smtpAuthenticatorWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme;;")));


/**
 This is the ONLY valid way to create a TBSMTPAuthenticator instance.

 @todo improve comment and intentions
 //  The class you get depends on the authenticationScheme parameter.
 //
 // @details class methods like + (id)alloc are invariant in the sense of subclassing.

 */
+ (id)authenticatorWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme andCredentialsProvider:(id<TBSMTPAuthenticatorCredentialsProvider>)credentialsProvider;

@end
