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

- (void)dealloc {
	[self releaseOutlets];
}

- (void)releaseOutlets {
	self.contentScrollView = nil;
	self.contentView = nil;
	self.progressView = nil;
	self.textView1 = nil;
	self.textView2 = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupScrollView];
	
	// Basic request
	[self runBasicRequest];
	
	// Downloading a file
	[self downloadFile];
	
	// Request that returns JSON
	[self runJSONRequest];
	
	// POST request
	[self runPOSTRequest];
}

- (void)setupScrollView {
	[self.contentScrollView addSubview:self.contentView];
	self.contentScrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - Requests

- (void)runBasicRequest {
	WCBasicConnectionRequest *basicRequest = [[WCBasicConnectionRequest alloc] init];
	basicRequest.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
	basicRequest.completionHandler = ^(id object) {
		
	};
	[basicRequest start];
}

- (void)downloadFile {
	self.progressView.progressTintColor = [UIColor blueColor];
	
	WCDownloadFileConnectionRequest *downloadFileRequest = [[WCDownloadFileConnectionRequest alloc] init];
	downloadFileRequest.progressHandler = ^(NSInteger downloaded, NSInteger total, double progress) {
		self.progressView.progress = progress;
	};
	downloadFileRequest.completionHandler = ^(id object) {
		self.progressView.progressTintColor = [UIColor greenColor];
	};
	[downloadFileRequest start];
}

- (void)runJSONRequest {
	WCIPTestConnectionRequest *jsonRequest = [[WCIPTestConnectionRequest alloc] init];
	jsonRequest.completionHandler = ^(id object) {
		self.textView1.text = [object description];
	};
	[jsonRequest start];
}

- (void)runPOSTRequest {
	WCJSONPostConnectionRequest *postRequest = [[WCJSONPostConnectionRequest alloc] init];
	postRequest.completionHandler = ^(id object) {
		self.textView2.text = [object description];
	};
	[postRequest start];
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
