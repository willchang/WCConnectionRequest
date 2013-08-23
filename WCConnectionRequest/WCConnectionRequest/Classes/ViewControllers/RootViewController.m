//
//  RootViewController.m
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import "RootViewController.h"
#import "WCDownloadFileConnectionRequest.h"

@implementation RootViewController

- (void)dealloc {
	[self releaseOutlets];
	[super dealloc];
}

- (void)releaseOutlets {
	self.contentScrollView = nil;
	self.contentView = nil;
	self.progressView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupScrollView];
	[self start];
}

- (void)setupScrollView {
	[self.contentScrollView addSubview:self.contentView];
	self.contentScrollView.contentSize = self.contentView.frame.size;
}

#pragma mark - Requests

- (void)downloadFile {
	WCDownloadFileConnectionRequest *downloadFileRequest = [[WCDownloadFileConnectionRequest alloc] init];
	downloadFileRequest.progressHandler = ^(NSInteger downloaded, NSInteger total, double progress) {
		self.progressView.progress = progress;
	};
	downloadFileRequest.completionHandler = ^(id object) {
		self.progressView.progressTintColor = [UIColor greenColor];
	};
	[downloadFileRequest start];
	[downloadFileRequest release];
}

#pragma mark - Actions

- (IBAction)start {
	[self downloadFile];
}

- (IBAction)cancelAll {
	[WCConnectionRequest cancelAllConnections];
	self.progressView.progress = 0.0;
}

@end
