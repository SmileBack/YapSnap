//
//  YSSpotifySourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSAudioSourceController.h"
#import <iCarousel/iCarousel.h>
#import "JEProgressView.h"
#import <StreamingKit/STKAudioPlayer.h>

@interface YSSpotifySourceController : YSAudioSourceController<iCarouselDataSource, iCarouselDelegate, UITextFieldDelegate, STKAudioPlayerDelegate>


@end
