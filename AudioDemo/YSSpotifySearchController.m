//
//  YSSpotifySearchController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSSpotifySearchController.h"
#import "SpotifyAPI.h"
#import "YSTrack.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import <QuartzCore/QuartzCore.h>

@interface YSSpotifySearchController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;

@end

@implementation YSSpotifySearchController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


@end
