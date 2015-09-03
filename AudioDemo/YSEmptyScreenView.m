//
//  YSEmptyScreenView.m
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSEmptyScreenView.h"

@implementation YSEmptyScreenView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = THEME_BACKGROUND_COLOR;
        self.layer.cornerRadius = 10;
        self.titleLabel = UILabel.new;
        self.explanationLabel = UILabel.new;
        for (UILabel *label in @[self.titleLabel, self.explanationLabel]) {
            [label setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:label];
            label.textColor = UIColor.whiteColor;
            label.textAlignment = NSTextAlignmentCenter;
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": label}]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:label == self.titleLabel ? -20 : 20]];
        }
        self.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:35];
        self.explanationLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    }
    return self;
}

- (CGSize)intrinsicContentSize{
    return CGSizeMake(300, 300);
}

@end
