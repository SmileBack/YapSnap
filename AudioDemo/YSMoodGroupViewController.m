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
                                    imageName:@"Mood_Flirtatious"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"nostaligic_tracks"
                                    imageName:@"Mood_Nostalgic"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"funny_tracks"
                                    imageName:@"Mood_Funny"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"celebratory_tracks"
                                    imageName:@"Mood_Celebratory"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"happy_tracks"
                                    imageName:@"Mood_Happy"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"sad_tracks"
                                    imageName:@"Mood_Sad"]
             ];
}

@end
