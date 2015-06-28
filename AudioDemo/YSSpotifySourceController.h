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

@interface YSSpotifySourceController : YSAudioSourceController<iCarouselDataSource, iCarouselDelegate, UITextFieldDelegate, STKAudioPlayerDelegate, UIAlertViewDelegate>

#define TAPPED_ALBUM_COVER @"yaptap.TappedAlbumCoverKey5"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DISMISS_KEYBOARD_NOTIFICATION @"DismissKeyboardNotification"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define RESET_BANNER_UI @"com.yapsnap.ResetSpotifyUINotification"
#define REMOVE_BOTTOM_BANNER_NOTIFICATION @"com.yapsnap.RemoveBottomBannerNotification"
#define LISTENED_TO_CLIP_NOTIFICATION @"com.yapsnap.ListenedToClipNotification"
#define RESET_BANNER_UI @"com.yapsnap.ResetSpotifyUINotification"
#define DID_SEE_TOP_CHARTS_POPUP_KEY @"yaptap.DidSeeTopChartsPopupKey602"
#define DISMISS_TOP_CHARTS_POPUP_NOTIFICATION @"DismissTopChartsPopup"
#define DID_PLAY_SONG_FOR_FIRST_TIME_KEY @"yaptap.DidPlaySongForFirstTimeKey"
#define DID_TAP_ARTIST_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.DidTapArtistButtonForFirstTimeKey"

@property (nonatomic, strong) NSString *selectedGenre;

@end
