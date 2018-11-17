//
//  TBSMTPRequest.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import <Foundation/Foundation.h>
#import "TBSMTPConstants.h"
#import "TBSMTPAuthenticator.h"

@class TBSMTPMessage;

@interface TBSMTPRequest : NSObject {
	NSString *_rawString;
}


@property (retain) NSString *rawString;
@property (readonly) NSData *rawData;


#pragma mark EHLO

+ (id)requestWithEHLO;
+ (id)requestWithEHLOAndGreeting:(NSString *)greeting;

#pragma mark MAIL

+ (id)requestWithMAILFROM:(NSString *)from;

#pragma mark RCPT

+ (id)requestWithRCPTTO:(NSString *)to;

#pragma mark AUTH

+ (id)requestWithAUTHWithAuthenticationScheme:(TBSMTPAuthenticationScheme)authenticationScheme;
+ (id)requestWithAUTHForRoundTripsResponseString:(NSString *)response;

#pragma mark DATA

+ (id)DATArequest;
+ (id)messageRequestWithMessage:(TBSMTPMessage *)message;

#pragma mark QUIT

+ (id)QUITrequest;

@end
