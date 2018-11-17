//
//  TBSMTPTransporter.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import <Foundation/Foundation.h>

#import "TBSMTPConstants.h"

#import "TBSMTPClient.h"
#import "TBSMTPServer.h"

@class TBSMTPResponse, TBSMTPRequest, GCDAsyncSocket;


/**
 TBSMTPProtocolProgressIndicator is used in the mean of a checklist. Every time
 a command is confirmed by the server the transporter TBSMTPProtocolProgressIndicator
 variable is or-ed with the TBSMTPCommand.
 */
typedef NSInteger TBSMTPProtocolProgressIndicator;


/**
 */
@interface TBSMTPTransporter : NSOperation {

	TBSMTPProtocolProgressIndicator _protocolProgressIndicator;
	TBSMTPMessage		*_message;
	TBSMTPServer		*_server;
	NSError				*_error;
	TBSMTPResponse		*_lastResponse;
	TBSMTPRequest		*_lastRequest;

	GCDAsyncSocket		*_socket;

	dispatch_queue_t		_connectionQueue;
	dispatch_semaphore_t	_connectionSemaphore;
	dispatch_semaphore_t	_readSemaphore;
	dispatch_semaphore_t	_writeSemaphore;
}


@property (readonly) TBSMTPProtocolProgressIndicator protocolProgressIndicator;		/**< The progress indicator */
@property (retain) TBSMTPMessage *message;					/**< The message to sent */
@property (retain) TBSMTPServer *server;					/**< The server the message is sent to */

/**
 @discussion If not nil an error occured while message transmission. The error 
 domain is TBSMTPTransporter, the code is set to the TBSMTPResponseType where the 
 error occured, userInfo is set to nil.
 
 @see TBSMTPResponseType
 */
@property (retain) NSError *error;				
@property (readonly, retain) TBSMTPResponse	*lastResponse;	/**< The last response the server sent back. */
@property (readonly, retain) TBSMTPRequest	*lastRequest;	/**< The last request sent to the server. */

/**
 !! use - (id)initWithMessage:(TBSMTPMessage *)message andSesrver:(TBSMTPServer *)server
 
 @see http://clang.llvm.org/docs/LanguageExtensions.html#messages-on-deprecated-and-unavailable-attributes
 */
- (id) init __attribute__((unavailable("init not available, use - (id)initWithMessage:(TBSMTPMessage *)message andSesrver:(TBSMTPServer *)server;")));

/**
 The designated initializer to instanciate a TBSMTPTransporter object
 */
- (id)initWithMessage:(TBSMTPMessage *)message andServer:(TBSMTPServer *)server;

@end



@interface TBSMTPTransporterVerify : TBSMTPTransporter


/**
 The designated initializer to instanciate a TBSMTPTransporter object
 */
- (id)initWithServer:(TBSMTPServer *)server;

@end

