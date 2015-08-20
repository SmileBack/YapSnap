//
//  YTTrackCategory.m
//  YapTap
//
//  Created by Dan B on 6/25/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTTrackGroup.h"

@implementation YTTrackGroup

+ (YTTrackGroup *)trackGroupWithName:(NSString *)name apiString:(NSString *)apiString {
    YTTrackGroup *group = YTTrackGroup.new;
    group.name = name;
    group.apiString = apiString;
    return group;
}

@end
