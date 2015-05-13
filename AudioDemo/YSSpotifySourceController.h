//
//  YSSpotifySourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSAudioSourceController.h"
#import <iCarousel/iCarousel.h>
#import <StreamingKit/STKAudioPlayer.h>

@interface YSSpotifySourceController : YSAudioSourceController<iCarouselDataSource, iCarouselDelegate, UITextFieldDelegate, STKAudioPlayerDelegate>

#define TAPPED_ALBUM_COVER @"yaptap.TappedAlbumCoverKey"
#define TAPPED_SONG_VERSION_ONE @"yaptap.TappedSongVersionOneKey"
#define TAPPED_SONG_VERSION_TWO @"yaptap.TappedSongVersionTwoKey"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DISMISS_KEYBOARD_NOTIFICATION @"DismissKeyboardNotification"
#define TAPPED_PROGRESS_BAR_NOTIFICATION @"TappedProgressBarNotification"
#define TAPPED_SHUFFLE_BUTTON @"yaptap.TappedShuffleButtonKey8"
#define SCROLLED_CAROUSEL @"yaptap.ScrolledCarouselKey7"
#define DID_VIEW_SPOTIFY_SONGS @"yaptap.DidViewSpotifySongs"
#define TAPPED_DICE_BUTTON @"yaptap.TappedDiceButton"
#define SEARCHED_FOR_SONG_NOTIFICATION @"yaptap.SearchedForSongNotification"

@property (nonatomic, strong) NSString *selectedGenre;

@end
