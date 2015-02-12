//
//  YSUser.h
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSUser : NSObject<NSCoding>

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSNumber *score;

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSString *sessionToken;
@property (nonatomic, strong) NSString *pushToken;

// Helpers for displaying these possibly-nil propertier
@property (nonatomic, readonly) NSString *displayEmail;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *displayFirstName;
@property (nonatomic, readonly) NSString *displayLastName;

+ (YSUser *) userFromDictionary:(NSDictionary *) dictionary;
+ (NSArray *) usersFromArray:(NSArray *)array;
+ (YSUser *) currentUser;
+ (void) setCurrentUser:(YSUser *)user;
+ (void) wipeCurrentUserData;

@property (nonatomic, readonly) BOOL isUserInfoComplete;
@property (nonatomic, readonly) BOOL hasSessionToken;

@end
