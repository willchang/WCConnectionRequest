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
#define API_ERROR(__domain__,__code__,__message__) [NSError errorWithDomain:__domain__ code:__code__ userInfo:@{NSLocalizedDescriptionKey : __message__}]
#define ERROR_CODE_CONNECTION_REQUEST_DEFAULT 31337

/*
 Completion blocks.
 */
typedef void (^WCConnectionRequestCompletionHandler)(NSError * _Nullable error, id _Nullable object);
typedef void (^WCConnectionRequestProgressHandler)(NSInteger bytesSoFar, NSInteger totalBytes, double progress);

/*
 HTTP methods.
 */
typedef NS_ENUM(NSInteger, HTTPMethodType) {
	HTTPMethodTypeGet,
	HTTPMethodTypePost,
	HTTPMethodTypePut,
	HTTPMethodTypeDelete
};

/*
 Connection Request. Can be used generally with WCBasicConnectionRequest or by subclassing for separate API calls.
 */
@interface WCConnectionRequest : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, readonly, nullable) NSURLResponse *urlResponse;
@property (nonatomic, readonly, nullable) NSDate *dateStarted;
@property (nonatomic, readonly, nullable) NSDate *dateFinished;
@property (nonatomic, readonly) BOOL isActive;								// Flag for whether the connection is currently in progress
@property (nonatomic, readonly) NSTimeInterval duration;					// Duration of connection
@property (nonatomic, readonly, nullable) NSString *connectionIdentifier;	// Unique identifier that is created when 'start' is called
@property (nonatomic, strong, nullable) NSURLSession *session;

- (nonnull NSURL *) url;
- (HTTPMethodType)HTTPMethod;
- (nonnull NSMutableURLRequest *)request;
- (nullable NSDictionary *)requestHeaderFields;
- (nullable NSData *)bodyData;
- (nullable id)parseCompletionData:(nullable NSData *)data;
- (nullable NSError *)parseError:(nullable NSError *)error;

- (void)startWithCompletionHandler:(nullable WCConnectionRequestCompletionHandler)completionHandler progressHandler:(nullable WCConnectionRequestProgressHandler)progressHandler;
- (void)startDownloadTaskWithCompletion:(nullable WCConnectionRequestCompletionHandler)completionHandler progressHandler:(nullable WCConnectionRequestProgressHandler)progressHandler;

+ (BOOL)connectionRequestInUse:(nonnull Class)connectionRequestClass;
+ (void)cancelConnectionsOfClass:(nonnull Class)connectionRequestClass;
+ (void)cancelAllConnections;
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

@property (nonatomic, strong, nonnull) NSURLRequest *request;

@end
