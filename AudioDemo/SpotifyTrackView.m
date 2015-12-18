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

- (void)setIsBlurred:(BOOL)isBlurred {
    [super setIsBlurred:isBlurred];
    [self bringSubviewToFront:self.spotifyButton];
}

@end

@interface YapTrackView()

@property UIView *trackInfoContainer;

@end

@implementation YapTrackView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.trackInfoContainer = UIView.new;
        self.playCountLabel = UILabel.new;
        self.artistAndSongLabel = UILabel.new;
        self.yapTextLabel = UILabel.new;
        self.senderProfilePicture = [[FBSDKProfilePictureView alloc] init];
        self.trackInfoContainer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        self.playCountLabel.textAlignment = NSTextAlignmentRight;
        self.yapTextLabel.textAlignment = NSTextAlignmentCenter;
        self.artistAndSongLabel.textAlignment = NSTextAlignmentLeft;
        self.yapTextLabel.font = [UIFont fontWithName:@"Futura-Medium" size:30];
        for (UIView *view in @[self.trackInfoContainer, self.playCountLabel, self.artistAndSongLabel, self.yapTextLabel, self.senderProfilePicture]) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:view];
        }
        for (UILabel *label in @[self.playCountLabel, self.artistAndSongLabel, self.yapTextLabel]) {
            label.textColor = UIColor.whiteColor;
        }
        for (UILabel *label in @[self.playCountLabel, self.artistAndSongLabel]) {
            label.font = [UIFont fontWithName:@"Futura-Medium" size:self.songNameLabel.font.pointSize];
        }
        // Constraints
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[artist]-[playCount]-|" options:0 metrics:nil views:@{@"artist": self.artistAndSongLabel, @"playCount": self.playCountLabel}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[sender(20)]-|" options:0 metrics:nil views:@{@"sender": self.senderProfilePicture}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[sender(20)]-|" options:0 metrics:nil views:@{@"sender": self.senderProfilePicture}]];
        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:self.yapTextLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0], [NSLayoutConstraint constraintWithItem:self.yapTextLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]]];
        for (UIView *view in @[self.trackInfoContainer, self.yapTextLabel]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(2)-[v]-(2)-|" options:0 metrics:nil views:@{@"v": view}]];
        }
        for (UIView *view in @[self.playCountLabel, self.artistAndSongLabel, self.trackInfoContainer]) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[v(20)]" options:0 metrics:nil views:@{@"v": view}]];
             [self addConstraints:@[[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-2]]];
        }
    }
    return self;
}

@end