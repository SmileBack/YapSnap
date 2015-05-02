//
//  YSAudioSourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSAudioSourceController.h"

@interface YSAudioSourceController ()

@end

@implementation YSAudioSourceController

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

- (void) resetUI
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];
}

- (YapBuilder *) getYapBuilder
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];

    return nil;
}

- (void) startPlayback{}
- (void) stopPlayback{}


// Only relevant for Spotify
- (void) tappedControlCenterButton:(NSString *)genre
{
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method!"];
}

@end
