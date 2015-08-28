//
//  YTTrackCategory.m
//  YapTap
//
//  Created by Dan B on 6/25/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTTrackGroup.h"

@implementation YTTrackGroup

+ (YTTrackGroup *)defaultTrackGroup {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [YTTrackGroup trackGroupWithName:@"Trending"
                                                apiString:@"trending_tracks"];
    });
    return sharedInstance;
}

+ (YTTrackGroup *)trackGroupWithName:(NSString *)name apiString:(NSString *)apiString {
    YTTrackGroup *group = YTTrackGroup.new;
    group.name = name;
    group.apiString = apiString;
    return group;
}

@end
