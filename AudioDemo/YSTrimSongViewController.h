//
//  YSTrimSongViewController.h
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSiTunesUpload.h"
#import "YSAudioSourceController.h"

@interface YSTrimSongViewController : YSAudioSourceViewController<UIScrollViewDelegate>
@property (nonatomic, strong) YSiTunesUpload *iTunesUpload;

@end
