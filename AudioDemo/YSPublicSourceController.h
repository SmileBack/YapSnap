//
//  YSPublicSourceController.h
//  YapTap
//
//  Created by Rudd Taylor on 12/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSAudioSourceController.h"
#import <STKAudioPlayer.h>

@interface YSPublicSourceController : YSAudioSourceViewController<STKAudioPlayerDelegate>

@property (nonatomic, strong) NSArray *yaps;

@end
