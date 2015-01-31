//
//  YSUser.m
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSUser.h"

@implementation YSUser

+ (YSUser *) userFromDictionary:(NSDictionary *)dictionary
{
    YSUser *user = [YSUser new];
    
    user.userID = dictionary[@"id"];
    user.email = dictionary[@"email"];
    user.firstName = dictionary[@"first_name"];
    user.lastName = dictionary[@"last_name"];
    user.phone = dictionary[@"phone"];

    user.createdAt = dictionary[@"created_at"];
    user.updatedAt = dictionary[@"updated_at"];
    user.sessionToken = dictionary[@"session_token"];
    user.pushToken = dictionary[@"push_token"];

    return user;
}

- (BOOL) stringIsIncomplete:(NSString *)string
{
    return !string || [string isKindOfClass:[NSNull class]] || [@"" isEqualToString:string];
}

- (BOOL) isUserInfoComplete
{
    return [self stringIsIncomplete:self.email] ||
        [self stringIsIncomplete:self.firstName] ||
        [self stringIsIncomplete:self.lastName];
}

@end
