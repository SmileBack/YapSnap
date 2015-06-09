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

#define TAPPED_ALBUM_COVER @"yaptap.TappedAlbumCoverKey5"
#define TAPPED_SONG_VERSION_ONE @"yaptap.TappedSongVersionOneKey"
#define TAPPED_SONG_VERSION_TWO @"yaptap.TappedSongVersionTwoKey"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DISMISS_KEYBOARD_NOTIFICATION @"DismissKeyboardNotification"
#define TAPPED_PROGRESS_BAR_NOTIFICATION @"TappedProgressBarNotification"
#define DID_TAP_DICE_BUTTON @"yaptap.DidTapDiceButtonKey10"
#define SCROLLED_CAROUSEL @"yaptap.ScrolledCarouselKey7"
#define DID_VIEW_SPOTIFY_SONGS @"yaptap.DidViewSpotifySongs"
#define TAPPED_DICE_BUTTON_NOTIFICATION @"yaptap.TappedDiceButtonNotification"
#define TAPPED_ALBUM_COVER_FIRST_TIME_NOTIFICATION @"yaptap.TappedAlbumCoverFirstTimeNotification5"
#define DID_SEE_SPOTIFY_POPUP_KEY @"yaptap.DidSeeSpotifyPopupKey15"
#define DISMISS_SPOTIFY_POPUP @"DismissSpotifyPopup"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"

@property (nonatomic, strong) NSString *selectedGenre;

@end
