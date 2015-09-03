//
//  YSAudioSourceNavigationController.m
//  YapTap
//
//  Created by Rudd Taylor on 8/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSAudioSourceNavigationController.h"

@implementation YSAudioSourceNavigationController

@synthesize audioCaptureDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
}

- (BOOL)startAudioCapture {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(startAudioCapture)]) {
        return [(id<YSAudioSource>)self.topViewController startAudioCapture];
    }

    return NO;
}

- (void)stopAudioCapture:(float)elapsedTime {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(stopAudioCapture)]) {
        [(id<YSAudioSource>)self.topViewController stopAudioCapture];
    }
}

- (YapBuilder *)getYapBuilder {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(getYapBuilder)]) {
        return [(id<YSAudioSource>)self.topViewController getYapBuilder];
    }
    return nil;
}

- (void)startPlayback {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(startPlayback)]) {
        [(id<YSAudioSource>)self.topViewController startPlayback];
    }
}

- (void)stopAudioCapture {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(stopAudioCapture)]) {
        return [(id<YSAudioSource>)self.topViewController stopAudioCapture];
    }
}

- (void)cancelPlayingAudio {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(cancelPlayingAudio)]) {
        return [(id<YSAudioSource>)self.topViewController cancelPlayingAudio];
    }
}

- (void)clearSearchResults {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(clearSearchResults)]) {
        return [(id<YSAudioSource>)self.topViewController clearSearchResults];
    }
}

- (void)searchWithText:(NSString *)text {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(searchWithText:)]) {
        return [(id<YSAudioSource>)self.topViewController searchWithText:text];
    }
}

- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(updatePlaybackProgress)]) {
        return [(id<YSAudioSource>)self.topViewController updatePlaybackProgress:playbackTime];
    }
}

- (NSString *)currentAudioDescription {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(currentAudioDescription)]) {
        return [(id<YSAudioSource>)self.topViewController currentAudioDescription];
    }
    return nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    if ([viewController conformsToProtocol:@protocol(YSAudioSource)]) {
        id<YSAudioSource> source = (id<YSAudioSource>)viewController;
        source.audioCaptureDelegate = self.audioCaptureDelegate;
    }
}

@end
