//
//  TBSMTPConstants.m
//  TBInternetProtocolKit
//
//  Created by Thomas Brandstätter on 05.09.13.
//

#include "TBSMTPConstants.h"


NSString * const kAuthenticationType_PlainString		= @"PLAIN";
NSString * const kAuthenticationType_LoginString		= @"LOGIN";
NSString * const kAuthenticationType_CRAM_MD5String		= @"CRAM-MD5";
NSString * const kAuthenticationType_DIGESTMD5String	= @"DIGEST-MD5";

NSString * const kRequestEOL				= @"\r\n";
NSString * const kRequestEOM				= @"\r\n.\r\n";