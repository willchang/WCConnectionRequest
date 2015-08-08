//
//  WCJSONPostConnectionRequest.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-25.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "WCPostConnectionRequest.h"

@interface WCPostConnectionRequest()
@property (nonatomic, copy) NSString *file;
@end

@implementation WCPostConnectionRequest

- (instancetype)initWithFile:(NSString *)file {
	if ((self = [super init])) {
		self.file = file;
	}
	return self;
}

- (HTTPMethod)httpMethod {
	return HTTPMethodPost;
}

- (NSData *)bodyData {
	return [NSData dataWithContentsOfFile:self.file];
}

- (NSURL *)url {
	return [NSURL URLWithString:@"http://posttestserver.com/post.php"];
}

@end
