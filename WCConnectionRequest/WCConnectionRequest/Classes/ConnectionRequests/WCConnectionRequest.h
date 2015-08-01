//
//  WCConnectionRequest.h
//  API
//
//  Created by William Chang on 2013-07-18.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Misc macros.
 */
#define API_ERROR(__code__,__message__) [NSError errorWithDomain:@"ConnectionRequestDomain" code:__code__ userInfo:@{NSLocalizedDescriptionKey : __message__}]
#define ERROR_CODE_CONNECTION_REQUEST_DEFAULT 31337

/*
 Console output.
 */
#if DEBUG
	#define CONNECTION_REQUEST_DEBUG_LOGGING 1
#else
	#define CONNECTION_REQUEST_DEBUG_LOGGING 0
#endif

/*
 Block definitions.
 */
typedef void (^WCConnectionRequestCompletionBlock)(id object);
typedef void (^WCConnectionRequestFailureBlock)(NSError *error);
typedef void (^WCConnectionRequestProgressBlock)(NSInteger bytesSoFar, NSInteger totalBytes, double progress);

/*
 HTTP methods.
 */
typedef enum {
	HTTPMethodGet,
	HTTPMethodPost,
	HTTPMethodPut,
} HTTPMethod;

/*
 ConnectionRequest protocol. A general list of methods that a ConnectionRequest object and its subclasses implements. No delegate is required.
 */
@protocol WCConnectionRequestProtocol <NSObject>
- (void)start;
- (void)startAndSaveToPath:(NSURL *)filePath;
- (void)cancel;

/*
 Subclasses must implement the required method below and any optional methods.
 */
@required
- (NSURL *)url;

@optional
- (HTTPMethod)httpMethod;
- (NSMutableURLRequest *)request;
- (NSDictionary *)requestHeaderFields;
- (NSData *)bodyData;
- (id)parseCompletionData:(NSData *)data;
- (void)handleResultObject:(id)resultObject;
- (NSError *)parseError:(NSError *)error;
- (void)handleConnectionError:(NSError *)error;
- (NSInteger)errorCode;
@end

/*
 Connection Request. Can be used generally with WCBasicConnectionRequest or by subclassing for separate API calls.
 */
@interface WCConnectionRequest : NSObject <WCConnectionRequestProtocol, NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
	NSURLConnection *_urlConnection;
	NSMutableData *_connectionData;
}

@property (nonatomic, readonly) NSURLResponse *urlResponse;
@property (nonatomic, readonly) NSDate *dateStarted;
@property (nonatomic, readonly) NSDate *dateFinished;
@property (nonatomic, readonly) NSURL *fileDestinationPath;					// A path to the file if it was downloaded (this is set on completion)
@property (nonatomic, readonly) BOOL isActive;								// Flag for whether the connection is currently in progress
@property (nonatomic, readonly) NSTimeInterval duration;					// Duration of connection
@property (nonatomic, readonly) NSString *connectionIdentifier;				// Unique identifier that is created when 'start' is called
@property (nonatomic, copy) WCConnectionRequestCompletionBlock completionHandler;
@property (nonatomic, copy) WCConnectionRequestFailureBlock failureHandler;
@property (nonatomic, copy) WCConnectionRequestProgressBlock progressHandler;

+ (BOOL)connectionRequestInUse:(Class)connectionRequestClass;
+ (void)cancelConnectionsOfClass:(Class)connectionRequestClass;
+ (void)cancelAllConnections;
- (void)start;
- (void)startAndSaveToPath:(NSURL *)filePath; // For saving to caches/temp/documents directories. If nil is provided, data is saved to temp folder with generated UUID for file name.
- (void)cancel;

@end

/*
 Connection request that converts the connection data into JSON in its parseCompletionData: method.
 */
@interface WCJSONConnectionRequest : WCConnectionRequest

@end

/*
 Basic connection request for when subclassing is not necessary or desired. Useful for one-off connection requests.
 A 'request' property is added so the user can simply set a customized NSURLRequest for the connection to use.
 */
@interface WCBasicConnectionRequest : WCConnectionRequest

@property (nonatomic, strong) NSURLRequest *request;

@end
