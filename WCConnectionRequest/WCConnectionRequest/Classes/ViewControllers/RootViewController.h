//
//  RootViewController.h
//  WCConnectionRequest
//
//  Created by William Chang on 2013-08-22.
//  Copyright (c) 2013 William Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UITextView *textView1;
@property (nonatomic, retain) IBOutlet UITextView *textView2;

- (IBAction)startDownload;
- (IBAction)cancelDownload;

@end
