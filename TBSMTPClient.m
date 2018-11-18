//
//  TBSMTPClient.h
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#import "TBSMTPClient.h"

#import "TBSMTPResponse.h"
#import "TBSMTPTransporter.h"


@implementation TBSMTPMessage : TBIMFMessage

@end


@implementation TBSMTPAddress : TBIMFAddress

@end


@interface TBSMTPClient ()

/**
 The queue where the TBSMTPMessages are processed on.
 
 @discussion Messages are dispatched on a non mainThread queue. 
 
 @see TBSMTPMessage
 */
@property (retain) NSOperationQueue *messagesProcessingQueue;

@end



@implementation TBSMTPClient


@synthesize messagesProcessingQueue = _messagesProcessingQueue;

- (id)init
{
    self = [super init];
    if (self) {
        _messagesProcessingQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_messagesProcessingQueue release]; _messagesProcessingQueue = nil;
    [super dealloc];
}

- (void)processMessage:(TBSMTPMessage *)message onServer:(TBSMTPServer *)server withCompletionBlock:(TBSMTPCompletionBlock)block {
    if (!(message && server)) {
        NSError *err = [NSError errorWithDomain:NSStringFromClass(self.class)
                                           code:-1
                                       userInfo:@{	 NSLocalizedDescriptionKey				: @"Unable to start processing"
                                                    ,NSLocalizedRecoverySuggestionErrorKey	: [NSString stringWithFormat:@"Provide missing argument '%@'.",(message == nil) ? @"message" : (server == nil) ? @"server" : @"(unknown)"]	}
                        ];
        if (block)
            block(NO,err);
        return;
    }
    
    __block TBSMTPTransporter *transporter = [[TBSMTPTransporter alloc] initWithMessage:message andServer:server];
    
    if (block)
        transporter.completionBlock = ^{
            
            TBDLogNetwork(@"transporter finisched with error %@", transporter.error);
            
            // ** TBSMTPResponseType_QUIT is correct error checking **

            BOOL success =	((transporter.protocolProgressIndicator & TBSMTPResponseType_DATA_SEND) == TBSMTPResponseType_DATA_SEND) ||
                            ((transporter.protocolProgressIndicator & TBSMTPResponseType_QUIT) == TBSMTPResponseType_QUIT);
            
            block(success, transporter.error);
        };
    
    NSArray *operationArray = @[ transporter ];
    [transporter release];
    [self.messagesProcessingQueue addOperations:operationArray waitUntilFinished:NO];
}

- (void)verifyCredentialsOnServer:(TBSMTPServer *)server withCompletionBlock:(TBSMTPCompletionBlock)block {
    if (!(server)) {
        NSError *err = [NSError errorWithDomain:NSStringFromClass(self.class)
                                           code:-1
                                       userInfo:@{	 NSLocalizedDescriptionKey				: @"Unable to start processing"
                        ,NSLocalizedRecoverySuggestionErrorKey	: [NSString stringWithFormat:@"Provide missing argument 'server'."]	}
                        ];
        if (block)
            block(NO,err);
        return;
    }
    
    
    __block TBSMTPTransporterVerify *transporter = [[TBSMTPTransporterVerify alloc] initWithServer:server];
    
    if (block)
        transporter.completionBlock = ^{
            
            TBDLogNetwork(@"transporter finished with error %@", transporter.error);
            
            BOOL success = transporter.error == nil;
            
            block(success, transporter.error);
        };
    
    NSArray *operationArray = @[ transporter ];
    [transporter release];
    [self.messagesProcessingQueue addOperations:operationArray waitUntilFinished:NO];
}

@end


