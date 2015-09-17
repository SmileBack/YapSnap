//
//  YSGenreGroupViewController.m
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSGenreGroupViewController.h"
#import "YTTrackGroup.h"

@interface YSGenreGroupViewController ()

@end

@implementation YSGenreGroupViewController

- (NSArray *)trackGroups {
    return @[
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"trending_tracks"
                                    imageName:@"Genre_HipHop"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"funny_tracks"
                                    imageName:@"Genre_Rock"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"nostalgic_tracks"
                                    imageName:@"Genre_Pop2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"flirtatious_tracks"
                                    imageName:@"Genre_EDM3"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"flirtatious_tracks"
                                    imageName:@"Genre_Country2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"flirtatious_tracks"
                                    imageName:@"Genre_Latin4"]
             ];
}

@end