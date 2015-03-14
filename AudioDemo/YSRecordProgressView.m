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
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ProgressViewNotches5.png"]];
    self.progressTintColor = [UIColor colorWithRed:245.0/255 green:75.0/255 blue:75.0/255 alpha:1.0];
    self.trackTintColor = UIColor.whiteColor;
    
    for (UIView* view in @[self.activityIndicator, imageView])
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