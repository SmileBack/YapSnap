//
//  YSUser.h
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSUser : NSObject

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *phone;

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSString *sessionToken;
@property (nonatomic, strong) NSString *pushToken;

@property (nonatomic, readonly) BOOL isUserInfoComplete;

+ (YSUser *) userFromDictionary:(NSDictionary *) dictionary;

@end
