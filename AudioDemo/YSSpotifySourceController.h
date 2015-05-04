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
#define VIEWED_RANDOM_PICK_ALERT @"yaptap.ViewedRandomPickAlert"
#define TAPPED_RESET_BUTTON @"yaptap.TappedResetButton"
#define TAPPED_SHUFFLE_BUTTON @"yaptap.TappedShuffleButton"
#define SHOW_CONTROL_CENTER @"yaptap.ShowControlCenterNotification"

@end
