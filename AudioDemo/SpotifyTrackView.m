//
//  SpotifyTrackView.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "SpotifyTrackView.h"

@implementation SpotifyTrackView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // SONG VERSION ONE BUTTON
        self.songVersionOneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // SONG VERSION TWO BUTTON
        self.songVersionTwoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // SPOTIFY BUTTON
        self.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];

        for (UIView* view in @[self.spotifyButton, self.songVersionOneButton, self.songVersionTwoButton]) {
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:view];
        }
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[view(30)]-|" options:0 metrics:nil views:@{@"view": self.spotifyButton}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view(30)]" options:0 metrics:nil views:@{@"view": self.spotifyButton}]];
        
        for (UIView *view in @[self.songVersionTwoButton, self.songVersionOneButton]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(50)]" options:0 metrics:nil views:@{@"view": view}]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:-2]];
        }
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.songVersionOneButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.songVersionTwoButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-3]];
        
    }
    return self;
}

@end