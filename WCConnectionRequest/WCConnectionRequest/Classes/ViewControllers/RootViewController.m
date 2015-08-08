//
//  RootViewController.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "RootViewController.h"
#import "WCDownloadFileConnectionRequest.h"
#import "WCJSONTestConnectionRequest.h"
#import "WCPostConnectionRequest.h"

@interface RootViewController() <NSURLSessionTaskDelegate>

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupScrollView];
	
	// Basic request
//	[self runBasicRequest];
	
	// Downloading a file
//	[self downloadFile];
	
	// Request that returns JSON
//	[self runJSONRequest];
	
	// POST request
	[self runPOSTRequest];
	
//	NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
//	[[session dataTaskWithURL:[NSURL URLWithString:@"https://api.github.com/users/willchang/repos"]] resume];
}

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
	NSLog(@"completed");
}

- (void)setupScrollView {
	[self.contentScrollView addSubview:self.contentView];
	self.contentScrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - Requests

- (void)runBasicRequest {
	WCBasicConnectionRequest *basicRequest = [[WCBasicConnectionRequest alloc] init];
	basicRequest.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
	[basicRequest startWithCompletionHandler:nil progressHandler:nil];
}

- (void)downloadFile {
	self.progressView.progressTintColor = [UIColor blueColor];
	
	WCDownloadFileConnectionRequest *downloadFileRequest = [[WCDownloadFileConnectionRequest alloc] init];
	[downloadFileRequest startDownloadTaskWithCompletion:^(NSError *error, id object) {
		NSLog(@"file location: %@", object);
	} progressHandler:^(NSInteger bytesSoFar, NSInteger totalBytes, double progress) {
		self.progressView.progress = progress;
	}];
}

- (void)runJSONRequest {
	WCJSONTestConnectionRequest *jsonRequest = [[WCJSONTestConnectionRequest alloc] init];
	[jsonRequest startWithCompletionHandler:^(NSError *error, id object) {
		self.textView1.text = [object description];
	} progressHandler:nil];
}

- (void)runPOSTRequest {
	WCPostConnectionRequest *postRequest = [[WCPostConnectionRequest alloc] initWithFile:[[NSBundle mainBundle] pathForResource:@"lorem-ipsum" ofType:@"txt"]];
	[postRequest startWithCompletionHandler:^(NSError *error, id object) {
		self.textView2.text = @"Done!";
	} progressHandler:^(NSInteger bytesSoFar, NSInteger totalBytes, double progress) {
		NSLog(@"Uploading progress: %f", progress);
	}];
}

#pragma mark - Actions

- (IBAction)startDownload {
	[self downloadFile];
}

- (IBAction)cancelDownload {
	[WCConnectionRequest cancelConnectionsOfClass:[WCDownloadFileConnectionRequest class]];
	self.progressView.progress = 0.0;
}
@end
