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
@property (strong, nonatomic) UIView *onboardingView;
@property (strong, nonatomic) UILabel *onboardingLabel;
@property (strong, nonatomic) UIImageView *onboardingImageView;

@end

@implementation YSRecentSourceController

- (void)viewWillAppear:(BOOL)animated {
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
        self.onboardingView.hidden = NO;
        [self setupOnboardingView];
    } else {
        self.onboardingView.hidden = YES;
        // Tell Spotify Source Controller to reload collection view
        [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_COLLECTION_VIEW object:nil];
    }
}

- (void) setupOnboardingView {
    self.onboardingView =[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.onboardingView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1.0];
    [self.view addSubview:self.onboardingView];
    
    self.onboardingImageView =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.onboardingImageView.image=[UIImage imageNamed:@"AlbumImagePlaceholder2.png"];
    [self.onboardingView addSubview:self.onboardingImageView];
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    effectView.frame =  CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.onboardingView addSubview:effectView];
    
    self.onboardingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 120)];
    self.onboardingLabel.text = @"No Recent\nMusic Clips";
    self.onboardingLabel.textColor = [UIColor whiteColor];
    self.onboardingLabel.textAlignment = NSTextAlignmentCenter;
    self.onboardingLabel.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    self.onboardingLabel.numberOfLines = 3;
    self.onboardingLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.onboardingLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.onboardingLabel.layer.shadowOpacity = 1.0f;
    self.onboardingLabel.layer.shadowRadius = 1.0f;
    [self.onboardingView addSubview:self.onboardingLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    // DON'T call super here
}

@end
