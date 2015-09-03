//
//  YSAudioSourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSAudioSourceController.h"

@implementation YSAudioSourceViewController

@synthesize audioCaptureDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
}

/**
 *  Returns YES if the capture started.
 */
- (BOOL) startAudioCapture
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];

    return NO;
}

- (void) stopAudioCapture:(float)elapsedTime
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];
}

- (YapBuilder *) getYapBuilder
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];
    return nil;
}

- (void) startPlayback{}
- (void) stopAudioCapture{}
- (void) cancelPlayingAudio{}
- (NSString *)currentAudioDescription {return nil;}

- (void)clearSearchResults {}
- (void)searchWithText:(NSString *)text {}
- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {}
- (void)prepareYapBuilder { [self.audioCaptureDelegate audioSourceControllerIsReadyToProduceYapBuidler:self]; }

@end
