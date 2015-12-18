//
//  YSAudioSourceNavigationController.m
//  YapTap
//
//  Created by Rudd Taylor on 8/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSAudioSourceNavigationController.h"
#import "ContactsViewController.h"

@interface YSAudioSourceNavigationController()

@property id observer;

@end

@implementation YSAudioSourceNavigationController

@synthesize audioCaptureDelegate = _audioCaptureDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:DID_SEND_YAP_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self popToRootViewControllerAnimated:NO];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer name:nil object:nil];
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

- (void)prepareYapBuilderWithOptions:(NSDictionary *)options {
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)] &&
        [self.topViewController respondsToSelector:@selector(prepareYapBuilderWithOptions:)]) {
        return [(id<YSAudioSource>)self.topViewController prepareYapBuilderWithOptions:options];
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
        [self.topViewController respondsToSelector:@selector(updatePlaybackProgress:)]) {
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

- (void)setAudioCaptureDelegate:(id<YSAudioSourceControllerDelegate>)audioCaptureDelegate {
    _audioCaptureDelegate = audioCaptureDelegate;
    if ([self.topViewController conformsToProtocol:@protocol(YSAudioSource)]) {
        id<YSAudioSource> source = (id<YSAudioSource>)self.topViewController;
        source.audioCaptureDelegate = self.audioCaptureDelegate;
    }
}

@end
