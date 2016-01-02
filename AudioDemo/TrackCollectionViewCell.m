//
//  SpotifyTrackCollectionViewCell.m
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "TrackCollectionViewCell.h"

@interface TrackCollectionOverlayView : UIView

@property UIImageView *imageView;
@property UIActivityIndicatorView *spinner;
@property UILabel *countdownLabel;
@property BOOL hidesAllButCountdown;

@end

@implementation TrackCollectionOverlayView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        self.imageView = [[UIImageView alloc] init];
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.spinner.center = self.center;
        self.countdownLabel = UILabel.new;
        self.countdownLabel.textColor = UIColor.whiteColor;
        self.countdownLabel.textAlignment = NSTextAlignmentCenter;
        self.countdownLabel.font = [UIFont fontWithName:@"Futura-Medium" size:20];
        for (UIView *view in @[self.imageView, self.spinner, self.countdownLabel]) {
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addSubview:view];
        }
        for (UIView *view in @[self.imageView, self.spinner]) {
            [self addConstraints:@[[NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:0],
                                   [NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0],
                                   [NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:46],
                                   [NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:46],
                                   ]];
        }
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[v(34)]" options:0 metrics:nil views:@{@"v": self.countdownLabel}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[v(34)]" options:0 metrics:nil views:@{@"v": self.countdownLabel}]];
    }
    return self;
}

- (void)setHidesAllButCountdown:(BOOL)hidesAllButCountdown {
    _hidesAllButCountdown = hidesAllButCountdown;
    self.backgroundColor = hidesAllButCountdown ? UIColor.clearColor : [UIColor colorWithWhite:0 alpha:0.8];
    self.spinner.hidden = hidesAllButCountdown;
    self.imageView.hidden = hidesAllButCountdown;
    self.countdownLabel.backgroundColor = hidesAllButCountdown ? [UIColor colorWithWhite:0 alpha:0.8] : UIColor.clearColor;
    self.countdownLabel.layer.cornerRadius = hidesAllButCountdown ? 17  : 0;
    self.countdownLabel.clipsToBounds = YES;
}

@end

@interface TrackCollectionViewCell()

@property TrackCollectionOverlayView* selectedOverlay;

@end

@implementation TrackCollectionViewCell

@synthesize state = _state, countdownTimer = _countdownTimer;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.trackView = [[TrackView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.trackView];
        [self.trackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected && !self.selectedOverlay) {
        self.selectedOverlay = TrackCollectionOverlayView.new;
        self.selectedOverlay.alpha = 0;
        [self.trackView insertSubview:self.selectedOverlay aboveSubview:self.trackView.imageView];
        [self.selectedOverlay setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.trackView addConstraints:@[[NSLayoutConstraint constraintWithItem:self.selectedOverlay attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.trackView.imageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.selectedOverlay attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.trackView.imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.selectedOverlay attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.trackView.imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                         [NSLayoutConstraint constraintWithItem:self.selectedOverlay attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.trackView.imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]]];
        [UIView animateWithDuration:0.2 animations:^{
            self.selectedOverlay.alpha = 1.0;
        }];
    } else if (!selected && self.selectedOverlay) {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectedOverlay.alpha = 0;
        } completion:^(BOOL finished) {
            [self.selectedOverlay removeFromSuperview];
            self.selectedOverlay = nil;
        }];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.selectedOverlay removeFromSuperview];
    self.selectedOverlay = nil;
    self.trackView.isBlurred = NO;
    self.trackView.songNameLabel.text = nil;
    [self.trackView.artistButton setTitle:nil forState:UIControlStateNormal];
}

- (void)setState:(TrackViewCellState)state {
    _state = state;
    if (self.selectedOverlay) {
        [self bringSubviewToFront:self.selectedOverlay];
    }
    switch (state) {
        case TrackViewCellStateBuffering:
            [self.selectedOverlay.spinner startAnimating];
            self.selectedOverlay.imageView.image = nil;
            self.selectedOverlay.countdownLabel.hidden = YES;
            self.selectedOverlay.countdownLabel.text = nil;
            break;
        case TrackViewCellStatePaused:
            [self.selectedOverlay.spinner stopAnimating];
            self.selectedOverlay.imageView.image = [UIImage imageNamed:@"play"];
            self.selectedOverlay.countdownLabel.hidden = YES;
            self.selectedOverlay.countdownLabel.text = nil;
            break;
        case TrackViewCellStatePlaying:
            [self.selectedOverlay.spinner stopAnimating];
            self.selectedOverlay.imageView.image = [UIImage imageNamed:@"pause"];
            self.selectedOverlay.countdownLabel.hidden = NO;
            break;
        default:
            break;
    }
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.2f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    
    [self.selectedOverlay.imageView.layer addAnimation:transition forKey:nil];
}

- (TrackViewCellState)state {
    return _state;
}

- (void)setCountdownTimer:(NSTimeInterval)countdownTimer {
    _countdownTimer = countdownTimer;
    self.selectedOverlay.countdownLabel.text = [NSString stringWithFormat:@"%@", @(_countdownTimer)];
}

- (NSTimeInterval)countdownTimer {
    return _countdownTimer;
}

@end

@implementation SpotifyTrackCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.trackView removeFromSuperview];
        self.trackView = [[SpotifyTrackView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.trackView];
        [self.trackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
    }
    return self;
}

@end

@implementation YapTrackCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.trackView removeFromSuperview];
        self.trackView = [[YapTrackView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.trackView];
        [self.trackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": self.trackView}]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.trackView.isBlurred = NO;
    self.trackView.senderProfilePicture.profileID = nil;
    self.trackView.imageView.layer.borderWidth = 0;
    self.trackView.imageView.layer.borderColor = nil;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.selectedOverlay.hidesAllButCountdown = YES;
    self.trackView.imageView.layer.borderColor = selected ? UIColor.redColor.CGColor : nil;
    self.trackView.imageView.layer.borderWidth = selected ? 2 : 0;
}

@end

@implementation TrackCollectionViewCell (STK)

- (void)updateWithState:(STKAudioPlayerState)state {
    if (state == STKAudioPlayerStateBuffering) {
        self.state = TrackViewCellStateBuffering;
    } else if (state == STKAudioPlayerStatePaused) {
        self.state = TrackViewCellStatePaused;
    } else if (state == STKAudioPlayerStateStopped) {
        self.state = TrackViewCellStateNone;
    } else  if (state == STKAudioPlayerStatePlaying) {
        self.state = TrackViewCellStatePlaying;
    }
}

- (void)setState:(TrackViewCellState)state {
    _state = state;
}

@end