//
//  MusicPlaybackVC.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "JEProgressView.h"
#import "YSYap.h"

@interface MusicPlaybackVC : UIViewController<STKAudioPlayerDelegate>
@property (nonatomic, strong) YSYap *yap;

- (void) stop;
@end
