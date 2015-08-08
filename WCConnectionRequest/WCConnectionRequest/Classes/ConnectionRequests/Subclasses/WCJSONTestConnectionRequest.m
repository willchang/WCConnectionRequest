//
//  WCIPTestConnectionRequest.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-25.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "WCJSONTestConnectionRequest.h"

@implementation WCJSONTestConnectionRequest

- (NSURL *)url {
	return [NSURL URLWithString:@"https://api.github.com/users/willchang/repos"];
}

@end
