//
//  SpotifyTrackView.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackView.h"
#import <FBSDKCoreKit/FBSDKProfilePictureView.h>
#import "YSYap.h"

@interface SpotifyTrackView : TrackView

@property (nonatomic, strong) UIButton *spotifyButton;
@property (nonatomic, strong) UIButton *songVersionOneButton;
@property (nonatomic, strong) UIButton *songVersionTwoButton;
@end

@interface YapTrackView: SpotifyTrackView

@property (nonatomic, strong) UILabel *playCountLabel;
@property (nonatomic, strong) UILabel *artistAndSongLabel;
@property (nonatomic, strong) UILabel *yapTextLabel;
@property (nonatomic, strong) FBSDKProfilePictureView *senderProfilePicture;
@property (nonatomic, strong) UIButton *likeButton;
@end