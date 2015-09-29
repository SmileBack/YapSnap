//
//  YSRecentSourceController.m
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSRecentSourceController.h"
#import "YapsCache.h"
#import "YSYap.h"
#import "YSEmptyScreenView.h"

#define RELOAD_COLLECTION_VIEW @"com.yapsnap.ReloadCollectionViewNotification"


@interface YSRecentSourceController()

@property (strong) YSEmptyScreenView *emptyView;

@end

@implementation YSRecentSourceController

- (void)viewWillAppear:(BOOL)animated {
//    [[YapsCache sharedCache] loadYapsWithCallback:^(NSArray *yaps, NSError *error) {
//        NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:yaps.count];
//        for (YSYap *yap in yaps) {
//            if (yap.track) {
//                [tracks addObject:yap.track];
//                NSLog(@"Songs: %@", yap.track);
//            }            
//        }
        NSArray *yaps = [YapsCache sharedCache].yaps;
    
        NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:yaps.count];
        for (YSYap *yap in yaps) {
            if (yap.track) {
                [tracks addObject:yap.track];
                NSLog(@"Songs: %@", yap.track);
            }
        }
    

    
    
        self.songs = tracks;
        if (self.songs.count == 0) {
            self.emptyView = [[YSEmptyScreenView alloc] initWithFrame:CGRectZero];
            [self.view addSubview:self.emptyView];
            [self.emptyView setTranslatesAutoresizingMaskIntoConstraints:NO];
            self.emptyView.titleLabel.text = @"No Recent Tracks";
            self.emptyView.explanationLabel.text = @"Send a Yap";
            [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:self.emptyView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                        [NSLayoutConstraint constraintWithItem:self.emptyView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]]];
        } else {
            [self.emptyView removeFromSuperview];
            self.emptyView = nil;
            
            // Tell Spotify Source Controller to reload collection view
            [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_COLLECTION_VIEW object:nil];
        }
    //}];
}

- (void)viewDidAppear:(BOOL)animated {
    // DON'T call super here
}

@end
