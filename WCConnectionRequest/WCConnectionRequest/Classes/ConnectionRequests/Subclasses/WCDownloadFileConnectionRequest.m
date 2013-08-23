//
//  WCDownloadFileConnectionRequest.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "WCDownloadFileConnectionRequest.h"

@implementation WCDownloadFileConnectionRequest

- (NSURL *)url {
	return [NSURL URLWithString:@"http://ipv4.download.thinkbroadband.com:8080/5MB.zip"];
}

@end
