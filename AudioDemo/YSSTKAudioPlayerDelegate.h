//
//  YSSTKAudioPlayerDelegate.h
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "AudioCaptureViewController.h"
#import "TrackCollectionViewCell.h"
#import "YSSongCollectionViewDataSource.h"

@interface YSSTKAudioPlayerDelegate : NSObject<STKAudioPlayerDelegate>
// To be set by user
@property (weak) id<YSAudioSourceControllerDelegate> audioCaptureDelegate;
@property (weak) id<YSAudioSource>audioSource;
@property UICollectionView *collectionView;

@property STKAudioPlayer *player;

- (BOOL)startAudioCaptureWithPreviewUrl:(NSString *)url withHeaders:(NSDictionary *)headers;
- (void)stopAudioCaptureFromCancel:(BOOL)fromCancel;
- (void)cancelPlayingAudio;
- (void)stopAudioCapture;
- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime;

@end
