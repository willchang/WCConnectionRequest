//
//  RootViewController.h
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UITextView *textView1;
@property (nonatomic, strong) IBOutlet UITextView *textView2;

- (IBAction)startDownload;
- (IBAction)cancelDownload;

@end
