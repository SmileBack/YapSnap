//
//  OffsetImageButton.m
//  YapTap
//
//  Created by Dan B on 3/14/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "OffsetImageButton.h"

static CGFloat const Offset = 30;

@interface OffsetImageButton()

@property UIImageView* offsetImageView;

@end

@implementation OffsetImageButton

@synthesize image = _image;

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
    self.backgroundColor = [UIColor colorWithRed:238.0/255 green:244.0/255 blue:249.0/255 alpha:1.0];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.offsetImageView removeFromSuperview];
    self.offsetImageView = [[UIImageView alloc] initWithImage:self.image];
    [self.offsetImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.offsetImageView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.offsetImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:self.reverseImageOffset ? Offset : -Offset]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.offsetImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    self.offsetImageView.contentMode = UIViewContentModeScaleToFill;
    self.offsetImageView.clipsToBounds = YES;
}

- (UIImage*)image
{
    return _image;
}

@end
