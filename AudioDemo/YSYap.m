//
//  YSYap.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSYap.h"

@implementation YSYap

+ (YSYap *) yapWithDictionary:(NSDictionary *)dict
{
    YSYap *yap = [YSYap new];
    
    yap.yapID = dict[@"id"];
    yap.createdAt = dict[@"created_at"];

    yap.playbackURL = @"https://s3.amazonaws.com/yapsnap/uploads/yap/recording/41/yap.m4a"; //@"https://p.scdn.co/mp3-preview/42fa6e912ef113dcd8d125abf08270fb5fea41af"; //TODO TOTAL HACK!!!!!!
    
    yap.senderID = dict[@"sender_id"];
    yap.senderName = dict[@"sender_name"];

    yap.receiverID = dict[@"receiver_id"];
    yap.receiverName = dict[@"receiver_name"];

    return yap;
}

+ (NSArray *) yapsWithArray:(NSArray *)array
{
    NSMutableArray *yaps = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        [yaps addObject:[YSYap yapWithDictionary:dict]];
    }
    return yaps;
}

@end
