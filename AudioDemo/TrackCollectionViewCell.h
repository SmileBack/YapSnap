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

typedef NS_ENUM(NSInteger, SpotifyTrackViewCellState) {
    SpotifyTrackViewCellStateNone,
    SpotifyTrackViewCellStatePlaying,
    SpotifyTrackViewCellStatePaused,
    SpotifyTrackViewCellStateBuffering,
};

@interface TrackCollectionViewCell: UICollectionViewCell

@property NSTimeInterval countdownTimer;
@property (nonatomic, strong) TrackView *trackView;
@property SpotifyTrackViewCellState state;

@end

@interface SpotifyTrackCollectionViewCell: TrackCollectionViewCell

@property (nonatomic, strong) SpotifyTrackView *trackView;

@end