//
//  SpotifyTrackCollectionViewCell.h
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackView.h"
#import "SpotifyTrackView.h"

typedef NS_ENUM(NSInteger, TrackViewCellState) {
    TrackViewCellStateNone,
    TrackViewCellStatePlaying,
    TrackViewCellStatePaused,
    TrackViewCellStateBuffering,
};

@interface TrackCollectionViewCell: UICollectionViewCell

@property NSTimeInterval countdownTimer;
@property (nonatomic, strong) TrackView *trackView;
@property TrackViewCellState state;

@end

@interface SpotifyTrackCollectionViewCell: TrackCollectionViewCell

@property (nonatomic, strong) SpotifyTrackView *trackView;

@end

#import <STKAudioPlayer.h>

@interface TrackCollectionViewCell (STK)

- (void)updateWithState:(STKAudioPlayerState)state;

@end