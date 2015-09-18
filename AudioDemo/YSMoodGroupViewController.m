//
//  YSMoodGroupViewController.m
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSMoodGroupViewController.h"
#import "YTTrackGroup.h"

@interface YSMoodGroupViewController ()

@end

@implementation YSMoodGroupViewController

- (NSArray *)trackGroups {
    return @[
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"flirtatious_tracks"
                                    imageName:@"Mood_Flirtatious2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"nostaligic_tracks"
                                    imageName:@"Mood_Nostalgic2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"funny_tracks"
                                    imageName:@"Mood_Funny2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"celebratory_tracks"
                                    imageName:@"Mood_Celebratory2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"happy_tracks"
                                    imageName:@"Mood_Happy2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"sad_tracks"
                                    imageName:@"Mood_Sad2"]
             ];
}

@end
