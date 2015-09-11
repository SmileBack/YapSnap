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
        self.backgroundColor = THEME_BACKGROUND_COLOR;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus"]];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        UILabel *label = UILabel.new;
        label.text = @"Upload a song";
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        
        // Constraints
        for (UIView *view in @[label, imageView]) {
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:view];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": view}]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:view == imageView ? -30 : 30]];
        }
    }
    return self;
}

@end
