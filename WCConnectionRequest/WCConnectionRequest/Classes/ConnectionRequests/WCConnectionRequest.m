//
//  WCConnectionRequest.m
//  API
//
//  Created by William Chang on 2013-07-18.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WCConnectionRequest.h"

@interface WCConnectionRequest()
@property (nonatomic, copy) WCConnectionRequestCompletionHandler completionHandler;
@property (nonatomic, copy) WCConnectionRequestProgressHandler progressHandler;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLSessionTask *sessionTask;
@property (nonatomic, strong) NSURL *downloadedFileLocation;
@end

@implementation WCConnectionRequest
@dynamic isActive, duration, urlResponse;

#pragma mark - ConnectionRequests / In Use

+ (NSMutableDictionary *)connectionRequests {
	static NSMutableDictionary *connectionRequests = nil;
	if (connectionRequests == nil) {
		connectionRequests = [[NSMutableDictionary alloc] init];
	}
	return connectionRequests;
}

+ (void)addActiveConnectionRequest:(WCConnectionRequest *)connectionRequest {
	NSString *className = NSStringFromClass([connectionRequest class]);
	NSMutableArray *requests = [[self connectionRequests] objectForKey:className];
	if (requests == nil) {
		requests = [[NSMutableArray alloc] initWithCapacity:1];
		[[self connectionRequests] setObject:requests forKey:className];
	}
	[requests addObject:connectionRequest];
	
	// Network activity
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

+ (void)removeActiveConnectionRequest:(WCConnectionRequest *)connectionRequest {
	NSMutableDictionary *connectionRequests = [self connectionRequests];
	
	NSString *className = NSStringFromClass([connectionRequest class]);
	NSMutableArray *requests = [connectionRequests objectForKey:className];
	[requests removeObject:connectionRequest];
	
	if ([requests count] == 0) {
		[connectionRequests removeObjectForKey:className];
	}
	
	// Network activity
	if ([connectionRequests count] == 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

+ (BOOL)connectionRequestInUse:(Class)connectionRequestClass {
	NSArray *requests = [[self connectionRequests] objectForKey:NSStringFromClass(connectionRequestClass)];
	return ([requests count] > 0);
}

+ (void)cancelConnectionsOfClass:(Class)connectionRequestClass {
	NSString *key = NSStringFromClass(connectionRequestClass);
	NSArray *connectionRequests = [[self connectionRequests] objectForKey:key];
	for (WCConnectionRequest *request in [NSArray arrayWithArray:connectionRequests]) {
		[request cancel];
	}
}

+ (void)cancelAllConnections {
	NSMutableDictionary *connectionRequests = [self connectionRequests];
	for (NSString *classString in [connectionRequests allKeys]) {
		[self cancelConnectionsOfClass:NSClassFromString(classString)];
	}
}

#pragma mark - NSURLSession

- (NSURLSession *)session {
	if (_session == nil) {
		_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
	}
	return _session;
}

#pragma mark - URL Response

- (NSURLResponse *)urlResponse {
	return self.sessionTask.response;
}

#pragma mark - HTTP method string

- (NSString *)stringForHTTPMethod:(HTTPMethod)method {
	NSString *string = @"GET";
	switch (method) {
		case HTTPMethodPost:
			string = @"POST";
			break;
		case HTTPMethodPut:
			string = @"PUT";
			break;
		case HTTPMethodDelete:
			string = @"DELETE";
		default:
			break;
	}
	
	return string;
}

#pragma mark - Start

- (void)prepareStart {
	_dateStarted = [NSDate date];
	_connectionIdentifier = [[self generateUUID] copy];
	self.data = [[NSMutableData alloc] init];
}

- (void)startWithCompletionHandler:(WCConnectionRequestCompletionHandler)completionHandler progressHandler:(WCConnectionRequestProgressHandler)progressHandler {
	[self reset];
	
	NSURLRequest *request = [self request];
	if (request) {
		[self prepareStart];
	
		self.completionHandler = completionHandler;
		self.progressHandler = progressHandler;
		
		switch (self.httpMethod) {
			case HTTPMethodGet:
			case HTTPMethodDelete:
				self.sessionTask = [self.session dataTaskWithRequest:request];
				self.data = [NSMutableData data];
				break;
			case HTTPMethodPost:
			case HTTPMethodPut:
				self.sessionTask = [self.session uploadTaskWithRequest:request fromData:self.bodyData];
				break;
			default:
				break;
		}
		
		[self doStart:request];
	} else {
#if DEBUG
		NSLog(@"Request is nil.");
#endif
	}
}

- (void)startDownloadTaskWithCompletion:(WCConnectionRequestCompletionHandler)completionHandler progressHandler:(WCConnectionRequestProgressHandler)progressHandler {
	[self reset];
	
	NSURLRequest *request = [self request];
	if (request) {
		[self prepareStart];
		
		self.progressHandler = progressHandler;
		self.completionHandler = completionHandler;
		self.sessionTask = [self.session downloadTaskWithRequest:request];
		
		[self doStart:request];
	} else {
#if DEBUG
		NSLog(@"Request is nil.");
#endif
	}
}

- (void)doStart:(NSURLRequest *)request {
	[self.sessionTask resume];
	[WCConnectionRequest addActiveConnectionRequest:self];
	[self logRequest:request];
}

- (NSString *)generateUUID {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidString = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return (__bridge NSString *)uuidString;
}

#pragma mark - Finish

- (void)connectionFinished {
	_dateFinished = [NSDate date];
	[WCConnectionRequest removeActiveConnectionRequest:self];
}

#pragma mark - Reset/Cancel

- (void)reset {
	_dateStarted = nil;
	_dateFinished = nil;
	_connectionIdentifier = nil;
	[self.sessionTask cancel];
	self.sessionTask = nil;
	self.data = nil;
	self.downloadedFileLocation = nil;
	[WCConnectionRequest removeActiveConnectionRequest:self];
}

- (void)cancel {
	[self logCancellationWithRequest:[self request]];
	[self.sessionTask cancel];
	[WCConnectionRequest removeActiveConnectionRequest:self];
}

#pragma mark - Is Active

- (BOOL)isActive {
	NSArray *connectionRequests = [[WCConnectionRequest connectionRequests] objectForKey:NSStringFromClass([self class])];
	return [connectionRequests indexOfObject:self] != NSNotFound;
}

#pragma mark - Duration

- (NSTimeInterval)duration {
	return [_dateFinished timeIntervalSinceDate:_dateStarted];
}

#pragma mark - Debug Logging

- (void)logRequest:(NSURLRequest *)request {
#if DEBUG
	NSString *className = NSStringFromClass([self class]);
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<---------------------------------------------- Request %@\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", _connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[request URL] absoluteString]];
	if ([request allHTTPHeaderFields].count) {
		[debugString appendFormat:@"\nRequest Header Fields:\n%@\n", [request allHTTPHeaderFields]];
	}
	NSData *bodyData = [request HTTPBody];
	[debugString appendFormat:@"\nRequest Body:\n%@\n", (bodyData != nil ? [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] : nil)];
	[debugString appendFormat:@"\n---------------------------------------------->> Request %@", className];
	NSLog(@"%@", debugString);
#endif
}

- (void)logResponseWithRequest:(NSURLRequest *)request data:(id)data parsedObject:(id)parsedObject error:(NSError *)error {
#if DEBUG
	NSString *className = NSStringFromClass([self class]);
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<********************************************* Response %@\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", _connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[self.urlResponse URL] absoluteString]];
	if ([self.urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		[debugString appendFormat:@"\nStatus:\n%d\n", (NSInteger)[(NSHTTPURLResponse *)self.urlResponse statusCode]];
		[debugString appendFormat:@"\nResponse Header Fields:\n%@\n", [(NSHTTPURLResponse *)self.urlResponse allHeaderFields]];
	}
	
	NSString *parsedObjectString = nil;
	if ([data isKindOfClass:[NSError class]]) {
		parsedObjectString = data;
	} else if ([data isKindOfClass:[NSData class]]) {
		parsedObjectString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		if (parsedObjectString == nil) {
			parsedObjectString = [NSString stringWithFormat:@"NSData with length %d", (NSInteger)((NSData *)data).length];
		}
	} else {
		parsedObjectString = [data description];
	}
	[debugString appendFormat:@"\nData:\n%@\n", parsedObjectString];
	
	[debugString appendFormat:@"\nParsed Object:\n%@: %@\n", [parsedObject class], parsedObject];
	[debugString appendFormat:@"\nError:\n%@\n", error];
	[debugString appendFormat:@"\nDuration: %f", [self duration]];
	[debugString appendFormat:@"\n*********************************************>> Response %@", className];
	NSLog(@"%@", debugString);
#endif
}

- (void)logCancellationWithRequest:(NSURLRequest *)request {
#if DEBUG
	NSString *className = NSStringFromClass([self class]);
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx %@ Cancelled\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", _connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[request URL] absoluteString]];
	if ([request allHTTPHeaderFields].count) {
		[debugString appendFormat:@"\nRequest Header Fields:\n%@\n", [request allHTTPHeaderFields]];
	}
	NSData *bodyData = [request HTTPBody];
	[debugString appendFormat:@"\nRequest Body:\n%@\n", (bodyData != nil ? [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] : nil)];
	[debugString appendFormat:@"\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx>> %@ Cancelled", className];
	NSLog(@"%@", debugString);
#endif
}

#pragma mark - REQUIRED METHODS TO BE IMPLEMENTED BY SUBCLASS

- (NSURL *)url {
	// Must be implemented by subclass
	[NSException raise:NSInternalInconsistencyException format:@"ConnectionRequest subclass must return a url. Otherwise BasicConnectionRequest should be used."];
	return nil;
}

#pragma mark - OPTIONAL METHODS TO BE IMPLEMENTED BY SUBCLASS

- (HTTPMethod)httpMethod {
	// Default implementation
	return HTTPMethodGet;
}

- (NSDictionary *)requestHeaderFields {
	// Default implementation. Subclass can override to return extra header fields where the key is the field name and value is the header value.
	return nil;
}

- (NSMutableURLRequest *)request {
	// Subclass may override if necessary to return a custom NSURLRequest. Otherwise, simply implement '-(NSURL *)url'.
	NSMutableURLRequest *request = nil;
	NSURL *url = [self url];
	if (url) {
		request = [NSMutableURLRequest requestWithURL:url];
		
		// Set method
		NSString *methodString = [self stringForHTTPMethod:[self httpMethod]];
		[request setHTTPMethod:methodString];
		
		// Set body data
		NSData *bodyData = [self bodyData];
		if (bodyData) {
			[request setHTTPBody:bodyData];
		}
		
		// Set header fields
		NSDictionary *headerFields = [self requestHeaderFields];
		for (NSString *key in [headerFields allKeys]) {
			[request addValue:[headerFields objectForKey:key] forHTTPHeaderField:key];
		}
	}
	return request;
}

- (NSData *)bodyData {
	// Default implementation: no data. The subclass would implement this method and return NSData to be put into the body of the HTTP request if desired.
	return nil;
}

- (id)parseCompletionData:(NSData *)data {
	// Default implementation: no parsing is done and connectionData is returned. A general subclass should override this for more specific functionality; return JSON object for example.
	return data;
}

- (NSError *)parseError:(NSError *)error {
	// Default implementation: pass the same error to the handler. Subclasses could create a user friendly error instead.
	return error;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(nonnull NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
	NSLog(@"URL session became invalid with error: %@", error);
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
	[self connectionFinished];
	
	__block id parsedObject = nil;
	__block NSError *urlSessionError = error;
	
	if ([self.sessionTask isKindOfClass:[NSURLSessionDownloadTask class]]) {
		parsedObject = self.downloadedFileLocation;
	} else if (error == nil) {
		parsedObject = [self parseCompletionData:self.data];
	}
	
	[self logResponseWithRequest:task.currentRequest data:self.data parsedObject:parsedObject error:error];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.completionHandler) {
			if ([parsedObject isKindOfClass:[NSError class]]) {
				urlSessionError = parsedObject;
				parsedObject = nil;
			}
			self.completionHandler(urlSessionError, parsedObject);
		}
	});
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
	if (self.progressHandler) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.progressHandler((NSInteger)totalBytesSent, (NSInteger)totalBytesExpectedToSend, (double)totalBytesSent / (double)totalBytesExpectedToSend);
		});
	}
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
	[self.data appendData:data];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	self.downloadedFileLocation = location;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	if (self.progressHandler) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.progressHandler((NSInteger)totalBytesWritten, (NSInteger)totalBytesExpectedToWrite, (double)totalBytesWritten / (double)totalBytesExpectedToWrite);
		});
	}
}

@end

@implementation WCJSONConnectionRequest

- (NSDictionary *)requestHeaderFields {
	return @{@"Content-Type": @"application/json"};
}

- (id)parseCompletionData:(NSData *)data {
	NSError *error = nil;
	id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
	if (error != nil) {
		object = error;
	}
	return object;
}

@end

@implementation WCBasicConnectionRequest


- (NSURL *)url {
	return [_request URL];
}

- (NSURLRequest *)request { // Override the superclass' request method to return the member variable instead.
	return _request;
}

@end
