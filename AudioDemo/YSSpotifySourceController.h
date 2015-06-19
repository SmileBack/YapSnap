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
#define TAPPED_SONG_VERSION_ONE @"yaptap.TappedSongVersionOneKey"
#define TAPPED_SONG_VERSION_TWO @"yaptap.TappedSongVersionTwoKey"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DISMISS_KEYBOARD_NOTIFICATION @"DismissKeyboardNotification"
#define SCROLLED_CAROUSEL @"yaptap.ScrolledCarouselKey7"
#define DID_VIEW_SPOTIFY_SONGS @"yaptap.DidViewSpotifySongs"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define RESET_BANNER_UI @"com.yapsnap.ResetSpotifyUINotification"
#define REMOVE_BOTTOM_BANNER_NOTIFICATION @"com.yapsnap.RemoveBottomBannerNotification"
#define LISTENED_TO_CLIP_NOTIFICATION @"com.yapsnap.ListenedToClipNotification"
#define CANCELED_BOTTOM_BANNER_NOTIFICATION @"com.yapsnap.CanceledBottomBannerNotification"
#define DID_VIEW_SEARCH_ARTIST_POPUP @"com.yapsnap.DidViewSearchArtistPopup"

@property (nonatomic, strong) NSString *selectedGenre;

@end
