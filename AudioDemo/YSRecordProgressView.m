//
//  YSRecordProgressView.m
//  YapTap
//
//  Created by Dan B on 3/14/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSRecordProgressView.h"

@interface YSRecordProgressView()

@property UIImageView* imageView;

@end

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
    
    self.progressViewStyle = UIProgressViewStyleBar;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ProgressViewNotches5.png"]];
    self.imageView.alpha = 0.2;

    self.progressTintColor = THEME_RED_COLOR;
    self.trackTintColor = UIColor.whiteColor;
    
    for (UIView* view in @[self.imageView, self.activityIndicator])
    {
        [self addSubview:view];
    }
}

- (void)layoutSubviews
{
    self.imageView.frame = self.bounds;
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [super layoutSubviews];
}

@end