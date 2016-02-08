//
//  GifCell.m
//  YapTap
//
//  Created by Rudd Taylor on 1/22/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

#import "GifCell.h"

@implementation GifCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.gifView = [[UIImageView alloc] init];
        self.gifView.translatesAutoresizingMaskIntoConstraints = NO;
        self.gifView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.gifView];
        // Constraints
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": self.gifView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.gifView}]];
    }
    return self;
}

@end