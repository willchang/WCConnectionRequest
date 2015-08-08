//
//  RootViewController.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "RootViewController.h"
#import "WCDownloadFileConnectionRequest.h"
#import "WCIPTestConnectionRequest.h"
#import "WCJSONPostConnectionRequest.h"

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupScrollView];
	
	// Basic request
//	[self runBasicRequest];
	
	// Downloading a file
	[self downloadFile];
	
	// Request that returns JSON
//	[self runJSONRequest];
	
	// POST request
//	[self runPOSTRequest];
}

- (void)setupScrollView {
	[self.contentScrollView addSubview:self.contentView];
	self.contentScrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - Requests

- (void)runBasicRequest {
	WCBasicConnectionRequest *basicRequest = [[WCBasicConnectionRequest alloc] init];
	basicRequest.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
	[basicRequest startDataTaskWithCompletion:nil];
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
	WCIPTestConnectionRequest *jsonRequest = [[WCIPTestConnectionRequest alloc] init];
	[jsonRequest startDataTaskWithCompletion:^(NSError *error, id object) {
		self.textView1.text = [object description];
	}];
}

- (void)runPOSTRequest {
	WCJSONPostConnectionRequest *postRequest = [[WCJSONPostConnectionRequest alloc] init];
	[postRequest startDataTaskWithCompletion:^(NSError *error, id object) {
		self.textView2.text = [object description];
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
