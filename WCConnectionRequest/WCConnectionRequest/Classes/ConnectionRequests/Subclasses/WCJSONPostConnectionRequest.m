//
//  WCJSONPostConnectionRequest.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-25.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "WCJSONPostConnectionRequest.h"

@implementation WCJSONPostConnectionRequest

- (HTTPMethod)httpMethod {
	return HTTPMethodPost;
}

- (NSURL *)url {
	NSString *jsonString = [@"{\"someKey\":\"someValuealue\"}" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [NSURL URLWithString:[@"http://validate.jsontest.com/?json=" stringByAppendingString:jsonString]];
}

@end
