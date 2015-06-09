//
//  SpotifyTrackView.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpotifyTrackView : UIView

@property (nonatomic, strong) NSString *spotifySongID;
@property (nonatomic, strong) NSString *spotifyURL;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *spotifyButton;

@property (nonatomic, strong) UIButton *songVersionOneButton;
@property (nonatomic, strong) UIButton *songVersionTwoButton;

@property (nonatomic, strong) UIButton *albumImageButton;

@property (nonatomic, strong) UIView *songVersionBackground;

@property (nonatomic, strong) UILabel *bannerLabel;

@end
