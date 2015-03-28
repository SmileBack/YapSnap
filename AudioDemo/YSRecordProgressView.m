//
//  YSRecordProgressView.m
//  YapTap
//
//  Created by Dan B on 3/14/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSRecordProgressView.h"

@implementation YSRecordProgressView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ProgressViewNotches5.png"]];
    imageView.alpha = 0.2;
    
    self.progressViewColor = THEME_RED_COLOR; //[UIColor colorWithRed:254.0/255 green:26.0/255 blue:64.0/255 alpha:1.0];
    self.progressTintColor = self.progressViewColor;
    self.trackTintColor = UIColor.whiteColor;
    
    for (UIView* view in @[imageView, self.activityIndicator])
    {
        [self addSubview:view];
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    for (UIView* view in @[imageView])
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:@{@"view": view}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view": view}]];
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];
}

@end