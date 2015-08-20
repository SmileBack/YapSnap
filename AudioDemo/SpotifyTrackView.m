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
        self.songNameLabel.font = [UIFont fontWithName:@"Futura-Medium" size:IS_IPHONE_4_SIZE ? 8 : 10];
        
        // ALBUM BUTTON
        self.albumImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.albumImageButton setImage:nil forState:UIControlStateNormal];
        
        // SPOTIFY BUTTON
        self.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
        
        // ARTIST BUTTON
        self.artistButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.artistButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:10]];
        self.artistButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.artistButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        
        // SONG VERSION ONE BUTTON
        self.songVersionOneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // SONG VERSION TWO BUTTON
        self.songVersionTwoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // RIBBON IMAGE
        self.ribbonImageView = [[UIImageView alloc] init];
        self.ribbonImageView.image = [UIImage imageNamed:@"TrendingRibbon6.png"];
        
        // ALBUM BANNER LABEL
        self.bannerLabel = [[UILabel alloc] init];
        self.bannerLabel.backgroundColor = THEME_RED_COLOR;
        self.bannerLabel.textAlignment = NSTextAlignmentCenter;
        self.bannerLabel.textColor = [UIColor whiteColor];
        self.bannerLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        self.bannerLabel.layer.borderWidth = 2;
        self.bannerLabel.hidden = YES;
        self.bannerLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        
        // Constraints
        for (UIView* view in @[self.imageView,  self.albumImageButton, self.bannerLabel, self.ribbonImageView, self.songVersionTwoButton, self.songVersionOneButton, self.spotifyButton, self.artistButton, self.songNameLabel]) {
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
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[view(20)]-|" options:0 metrics:nil views:@{@"view": self.spotifyButton}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view(20)]" options:0 metrics:nil views:@{@"view": self.spotifyButton}]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view(42)]" options:0 metrics:nil views:@{@"view": self.bannerLabel}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view(42)]" options:0 metrics:nil views:@{@"view": self.bannerLabel}]];
        
        for (UIView *view in @[self.songVersionTwoButton, self.songVersionOneButton]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(50)]" options:0 metrics:nil views:@{@"view": view}]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:-2]];
        }
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.songVersionOneButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.songVersionTwoButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-3]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view(110)]" options:0 metrics:nil views:@{@"view": self.ribbonImageView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view(110)]" options:0 metrics:nil views:@{@"view": self.ribbonImageView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[track(13)]-(0)-[artist(13)]-(0)-|" options:0 metrics:nil views:@{@"image": self.imageView, @"track": self.songNameLabel, @"artist": self.artistButton}]];
    }
    return self;
}

@end

@implementation SpotifyTrackCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.trackView = [[SpotifyTrackView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.trackView];
        [self.trackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderColor = selected ? THEME_RED_COLOR.CGColor : nil;
    self.layer.borderWidth = selected ? 2 : 0;
}

@end