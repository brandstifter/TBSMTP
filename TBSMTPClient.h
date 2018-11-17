//
//  TBSMTPClient.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import <Foundation/Foundation.h>
#import "TBIMFMessage.h"


@class TBSMTPServer;



@interface TBSMTPMessage : TBIMFMessage

@end

@interface TBSMTPAddress : TBIMFAddress

@end

/**
 This special block type is called after the processMessage:onServer:withCompletionBlock:
 returns.

 @param success	YES if all went well, otherwise NO.
 @param error	If success is NO an error instance is set, otherwise nil.  

 @discussion The error property of the transporter object indicates an error.

 */
typedef void(^TBSMTPCompletionBlock)(BOOL success, NSError *error);



/**
 TBSMTPClient
 
 This class is acts as a client for a SMTP Server. Internally TBSMTPClient 
 process message transmission with a NSOperationQueue. Therefore message sending
 has no impact on the calling thread.
 */
@interface TBSMTPClient : NSObject {
	NSOperationQueue *_messagesProcessingQueue;
}


/**
 Initiate a connection to the given server and send the given message. 
 
 @param message	The message to send
 @param server	The server used for transmitting the message
 @param block	The block to executed after the transmission ends
 */
- (void)processMessage:(TBSMTPMessage *)message onServer:(TBSMTPServer *)server withCompletionBlock:(TBSMTPCompletionBlock)block;

/**
 Validate the user credentials through login.
 
 @param server	The server used for transmitting the message
 @param block	The block to executed after the transmission ends
 */
- (void)verifyCredentialsOnServer:(TBSMTPServer *)server withCompletionBlock:(TBSMTPCompletionBlock)block;

@end
