//
//  SongGroupCollectionViewCell.m
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "SongGroupCollectionViewCell.h"

@implementation SongGroupCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView = UIImageView.new;
        self.imageView.image = [UIImage imageNamed:@"background"];
        self.label = UILabel.new;
        self.label.textColor = UIColor.whiteColor;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont fontWithName:@"Futura-Medium" size:20];
        for (UIView *view in @[self.imageView, self.label]) {
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.contentView addSubview:view];
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": view}]];
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": view}]];
        }
    }
    return self;
}

@end
