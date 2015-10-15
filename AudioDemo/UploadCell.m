//
//  UploadCell.m
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UploadCell.h"

@implementation UploadCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIView *container = UIView.new;
        [self addSubview:container];
        container.backgroundColor = THEME_BACKGROUND_COLOR;
        container.layer.borderWidth = 2;
        container.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        UILabel *label = UILabel.new;
        label.text = @"Tap to Upload";
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        
        // Constraints
        for (UIView *view in @[label, imageView, container]) {
            if (view != container) {
                [container addSubview:view];
            }
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": view}]];
        }
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]" options:0 metrics:nil views:@{@"v": container}]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:container attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        
        for (UIView *view in @[label, imageView]) {
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:view == imageView ? -30 : 30]];
        }
    }
    return self;
}

@end
