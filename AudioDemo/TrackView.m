//
//  TrackView.m
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "TrackView.h"

@implementation TrackView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // ALBUM IMAGE
        self.imageView = [[UIImageView alloc] init];
        self.imageView.layer.borderWidth = 2;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
        [self.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.05]];
        
        // SONG NAME LABEL
        self.songNameLabel = [[UILabel alloc] init];
        self.songNameLabel.textColor = UIColor.blackColor;
        self.songNameLabel.backgroundColor = [UIColor clearColor];
        self.songNameLabel.textAlignment = NSTextAlignmentCenter;
        self.songNameLabel.font = [UIFont fontWithName:@"Futura-Medium" size:IS_IPHONE_4_SIZE ? 8 : 12];
        
        // ALBUM BUTTON
        self.albumImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.albumImageButton setImage:nil forState:UIControlStateNormal];
        
        // ARTIST BUTTON
        self.artistButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.artistButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:10]];
        self.artistButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.artistButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateNormal];
        
        // Constraints
        for (UIView* view in @[self.imageView,  self.albumImageButton, self.artistButton, self.songNameLabel]) {
            [self addSubview:view];
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        }
        
        for (UIView *view in @[self.imageView, self.artistButton, self.albumImageButton, self.songNameLabel]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:@{@"view": view}]];
        }
        
        for (UIView *view in @[self.imageView, self.albumImageButton]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]" options:0 metrics:nil views:@{@"view": view}]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        }
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[image]-(2)-[track(13)]-(0)-[artist(13)]" options:0 metrics:nil views:@{@"image": self.imageView, @"track": self.songNameLabel, @"artist": self.artistButton}]];
    }
    return self;
}

@end
