//
//  WCConnectionRequest.m
//  API
//
//  Created by William Chang on 2013-07-18.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "WCConnectionRequest.h"

static NSMutableDictionary *connectionRequests = nil;

@implementation WCConnectionRequest
@synthesize completionHandler, failureHandler, progressHandler;
@synthesize dateStarted, dateFinished;
@synthesize urlResponse;
@synthesize fileDestinationPath;
@synthesize connectionIdentifier;
@dynamic isActive, duration;

- (void)dealloc {
	[urlConnection release];
	[connectionData release];
	[completionHandler release];
	[failureHandler release];
	[progressHandler release];
	[dateStarted release];
	[dateFinished release];
	[urlResponse release];
	[fileDestinationPath release];
	[connectionIdentifier release];
	[super dealloc];
}

#pragma mark - ConnectionRequests / In Use

+ (NSMutableDictionary *)connectionRequests {
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
		[requests release];
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

+ (void)cancelAllConnectionsOfClass:(Class)connectionRequestClass {
	NSString *key = NSStringFromClass(connectionRequestClass);
	NSArray *connectionRequests = [[self connectionRequests] objectForKey:key];
	for (WCConnectionRequest *request in [NSArray arrayWithArray:connectionRequests]) {
		[request cancel];
	}
}

+ (void)cancelAllConnections {
	NSMutableDictionary *connectionRequests = [self connectionRequests];
	for (NSString *classString in [connectionRequests allKeys]) {
		[self cancelAllConnectionsOfClass:NSClassFromString(classString)];
	}
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
		default:
			break;
	}
	
	return string;
}

#pragma mark - Start

- (void)start {
	[self reset];
	
	NSURLRequest *request = [self request];
	if (request) {
		dateStarted = [[NSDate date] retain];
		
		connectionIdentifier = [[self generateUUID] copy];
		
		urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
		[WCConnectionRequest addActiveConnectionRequest:self];
		
#if CONNECTION_REQUEST_DEBUG_LOGGING
		[self logRequest];
#endif
	}
}

- (void)startAndSaveToPath:(NSURL *)filePath {
	// If no filePath provided, create UUID for file name and save to temp folder
	if (filePath == nil) {
		filePath = [NSURL URLWithString:NSTemporaryDirectory()];
	}
	[fileDestinationPath release];
	fileDestinationPath = [filePath retain];
	[self start];
}

- (NSString *)generateUUID {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidString = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [(NSString *)uuidString autorelease];
}

#pragma mark - Reset/Cancel

- (void)reset {
	[dateStarted release];
	dateStarted = nil;
	
	[dateFinished release];
	dateFinished = nil;
	
	[connectionData release];
	connectionData = nil;
	
	[urlResponse release];
	urlResponse = nil;
	
	[fileDestinationPath release];
	fileDestinationPath = nil;
	
	[connectionIdentifier release];
	connectionIdentifier = nil;
	
	[urlConnection cancel];
	[urlConnection release];
	urlConnection = nil;
	[WCConnectionRequest removeActiveConnectionRequest:self];
}

- (void)cancel {
#if CONNECTION_REQUEST_DEBUG_LOGGING
	[self logCancellation];
#endif
	
	[self reset];
}

#pragma mark - Is Active

- (BOOL)isActive {
	NSArray *connectionRequests = [[WCConnectionRequest connectionRequests] objectForKey:NSStringFromClass([self class])];
	return [connectionRequests indexOfObject:self] != NSNotFound;
}

#pragma mark - Duration

- (NSTimeInterval)duration {
	return [dateFinished timeIntervalSinceDate:dateStarted];
}

#pragma mark - Connection Delegate

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if (self.progressHandler) {
		self.progressHandler(totalBytesWritten, totalBytesExpectedToWrite, totalBytesWritten / (double)totalBytesExpectedToWrite);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[urlResponse release];
	urlResponse = [response retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
	if (connectionData == nil) {
		connectionData = [[NSMutableData alloc] init];
	}
	[connectionData appendData:theData];
	
	if (self.progressHandler) {
		long long totalBytes = [self.urlResponse expectedContentLength];
		NSUInteger totalBytesWritten = [connectionData length];
		double progress = totalBytesWritten / (double)totalBytes;
		self.progressHandler(totalBytesWritten, totalBytes, progress);
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	dateFinished = [[NSDate date] retain];

	// Save data to file path if startAndSaveToPath: was called
	if (fileDestinationPath) {
		[[NSFileManager defaultManager] createFileAtPath:[fileDestinationPath absoluteString] contents:connectionData attributes:nil];
	}
	
	// Remove from collection of active connection requests
	[WCConnectionRequest removeActiveConnectionRequest:self];
	
	// Parse connection data
	id parsedObject = [self parseCompletionData:connectionData];
	
	// Handle parsed object
	[self handleResultObject:parsedObject];
	
	// Debug logging
#if CONNECTION_REQUEST_DEBUG_LOGGING
	[self logResponseWithObject:parsedObject];
#endif
	
	// Broadcast notification that this API call finished
	NSString *notificationName = [NSStringFromClass([self class]) stringByAppendingString:@"DidFinishNotification"];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  self, @"WCConnectionRequest",
							  parsedObject, @"ParsedObject",
							  nil];
	NSNotification *finishedNotification = [NSNotification notificationWithName:notificationName object:nil userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:finishedNotification];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[WCConnectionRequest removeActiveConnectionRequest:self];
	
#if CONNECTION_REQUEST_DEBUG_LOGGING
	[self logResponseWithObject:error];
#endif
	
	// Parse the error
	NSError *userError = [self parseError:error];
	
	// Handle error
	[self handleConnectionError:userError];
}

#pragma mark - Debug Logging

- (void)logRequest {
	NSString *className = NSStringFromClass([self class]);
	NSURLRequest *request = [self request];
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<---------------------------------------------- Request %@\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", self.connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[request URL] absoluteString]];
	[debugString appendFormat:@"\nRequest Header Fields:\n%@\n", [request allHTTPHeaderFields]];
	NSData *bodyData = [request HTTPBody];
	[debugString appendFormat:@"\nRequest Body:\n%@\n", (bodyData != nil ? [[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] autorelease] : nil)];
	[debugString appendFormat:@"\n---------------------------------------------->> Request %@", className];
	NSLog(@"%@", debugString);
}

- (void)logResponseWithObject:(id)object {
	NSString *className = NSStringFromClass([self class]);
	NSURLRequest *request = [self request];
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<********************************************* Response %@\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", self.connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[self.urlResponse URL] absoluteString]];
	if ([self.urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		[debugString appendFormat:@"\nStatus:\n%d\n", [(NSHTTPURLResponse *)self.urlResponse statusCode]];
		[debugString appendFormat:@"\nResponse Header Fields:\n%@\n", [(NSHTTPURLResponse *)self.urlResponse allHeaderFields]];
	}
	NSString *parsedObjectString = nil;
	if ([object isKindOfClass:[NSError class]]) {
		parsedObjectString = object;
	} else {
		parsedObjectString = ([object isKindOfClass:[NSData class]] ? [NSString stringWithFormat:@"NSData with length: %d", [(NSData *)object length]] : [object description]);
	}
	[debugString appendFormat:@"\nResult Object:\n%@\n", parsedObjectString];
	[debugString appendFormat:@"\nDuration: %f", [self duration]];
	[debugString appendFormat:@"\n*********************************************>> Response %@", className];
	NSLog(@"%@", debugString);
}

- (void)logCancellation {
	NSString *className = NSStringFromClass([self class]);
	NSURLRequest *request = [self request];
	
	NSMutableString *debugString = [NSMutableString string];
	[debugString appendFormat:@"\n<<xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx %@ Cancelled\n", className];
	[debugString appendFormat:@"\nConnection Identifier:\n%@\n", self.connectionIdentifier];
	[debugString appendFormat:@"\nURL:\n%@ %@\n", [request HTTPMethod], [[request URL] absoluteString]];
	[debugString appendFormat:@"\nRequest Header Fields:\n%@\n", [request allHTTPHeaderFields]];
	NSData *bodyData = [request HTTPBody];
	[debugString appendFormat:@"\nRequest Body:\n%@\n", (bodyData != nil ? [[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] autorelease] : nil)];
	[debugString appendFormat:@"\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx>> %@ Cancelled", className];
	NSLog(@"%@", debugString);
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

- (void)handleResultObject:(id)resultObject {
	// If necessary, subclasses should override this method and then call super to pass data to the completionHandler.
	if ([resultObject isKindOfClass:[NSError class]]) { // Handling an error here in case a project-contextual error was returned (a successful connection with an undesired result)
		if (self.failureHandler) {
			self.failureHandler(resultObject);
		}
	} else {
		if (self.completionHandler) {
			self.completionHandler(resultObject);
		}
	}
}

- (NSError *)parseError:(NSError *)error {
	// Default implementation: pass the same error to the handler. Subclasses could create a user friendly error instead.
	return error;
}

- (void)handleConnectionError:(NSError *)error {
	// If necessary, subclasses should override this method and then call super to pass data to the failureHandler.
	if (self.failureHandler) {
		self.failureHandler(error);
	}
}

- (NSInteger)errorCode {
	// Default error code. This method is currently not used by default to show or present errors. It can be used for convenience if subclasses implement it and handle errors.
	return ERROR_CODE_CONNECTION_REQUEST_DEFAULT;
}

@end

@implementation WCJSONConnectionRequest

- (id)parseCompletionData:(NSData *)data {
	NSError *error = nil;
	id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	if (error != nil) {
		object = error;
	}
	return object;
}

@end

@implementation WCBasicConnectionRequest
@synthesize request;

- (void)dealloc {
	[request release];
	[super dealloc];
}

- (NSURL *)url {
	return [request URL];
}

- (NSURLRequest *)request { // Override the superclass' request method to return the member variable instead.
	return request;
}

@end
