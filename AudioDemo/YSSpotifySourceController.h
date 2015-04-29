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
#define TAPPED_PROGRESS_VIEW_NOTIFICATION @"yaptap.TappedProgressViewNotification"
#define VIEWED_SONG_GENRE_VIEW @"yaptap.ViewedSongGenreViewNotification"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define VIEWED_SONG_GENRE_NOTIFICATION @"yaptap.ViewedSongGenreNotification"
#define SHOW_SONG_GENRE_VIEW @"yaptap.ShowSongGenreViewNotification"
#define HIDE_SONG_GENRE_VIEW @"yaptap.HideSongGenreViewNotification"

@end
