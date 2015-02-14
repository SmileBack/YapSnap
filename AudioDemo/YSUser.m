//
//  YSUser.m
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSUser.h"
#import "ContactManager.h"

#define USER_KEY @"com.yapsnap.CurrentUser"
static YSUser *currentUser;

@implementation YSUser

+ (YSUser *) userFromDictionary:(NSDictionary *)dictionary
{
    YSUser *user = [YSUser new];
    
    user.userID = dictionary[@"id"];
    user.email = dictionary[@"email"];
    user.firstName = dictionary[@"first_name"];
    user.lastName = dictionary[@"last_name"];
    user.phone = dictionary[@"phone"];
    user.score = dictionary[@"score"];

    user.createdAt = dictionary[@"created_at"];
    user.updatedAt = dictionary[@"updated_at"];
    user.sessionToken = dictionary[@"session_token"];
    user.pushToken = dictionary[@"push_token"];

    return user;
}

+ (NSArray *) usersFromArray:(NSArray *)array
{
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        [users addObject:[YSUser userFromDictionary:dict]];
    }
    return users;
}

+ (YSUser *) currentUser
{
    if (!currentUser) {
        currentUser = [YSUser userFromDisk];
    }
    return currentUser;
}

- (BOOL) stringIsIncomplete:(NSString *)string
{
    return !string || [string isKindOfClass:[NSNull class]] || [@"" isEqualToString:string];
}

- (BOOL) isUserInfoComplete
{
    BOOL emailIncomplete = [self stringIsIncomplete:self.email];
    BOOL firstNameIncomplete = [self stringIsIncomplete:self.firstName];
    BOOL lastNameIncomplete = [self stringIsIncomplete:self.lastName];
    
    return (emailIncomplete || firstNameIncomplete || lastNameIncomplete);
}

- (BOOL) hasSessionToken
{
    return ![self stringIsIncomplete:self.sessionToken];
}

#pragma mark - Display Properties
- (NSString *) displayStringForString:(NSString *) string
{
    if (!string || [string isKindOfClass:[NSNull class]]) {
        return @"";
    }
    return string;
}

- (NSString *) displayEmail
{
    return [self displayStringForString:self.email];
}

- (NSString *) displayName
{
    if (_displayName) {
        return _displayName;
    }

    _displayName = [[ContactManager sharedContactManager] nameForPhoneNumber:self.phone];
    if (_displayName) {
        return _displayName;
    }
    
    NSString *first = self.displayFirstName;
    NSString *last = self.displayLastName;
    
    if ([@"" isEqualToString:first]) {
        _displayName = last;
    } else if ([@"" isEqualToString:last]) {
        _displayName = first;
    } else {
        _displayName = [NSString stringWithFormat:@"%@ %@", first, last];
    }
    return _displayName;
}

- (NSString *) displayFirstName
{
    return [self displayStringForString:self.firstName];
}

- (NSString *) displayLastName
{
    return [self displayStringForString:self.lastName];
}

#pragma mark - User persisting

+ (YSUser *) userFromDisk
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [defaults objectForKey:USER_KEY];
    YSUser *user = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    return user;
}

+ (void) setCurrentUser:(YSUser *)user
{
    currentUser = user;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:user];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:encodedObject forKey:USER_KEY];
        [defaults synchronize];
    });
}

+ (void) wipeCurrentUserData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:USER_KEY];
        [defaults synchronize];
    });
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.userID forKey:@"userID"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.firstName forKey:@"firstName"];
    [encoder encodeObject:self.lastName forKey:@"lastName"];
    [encoder encodeObject:self.phone forKey:@"phone"];

    [encoder encodeObject:self.createdAt forKey:@"createdAt"];
    [encoder encodeObject:self.updatedAt forKey:@"updatedAt"];
    [encoder encodeObject:self.sessionToken forKey:@"sessionToken"];
    [encoder encodeObject:self.pushToken forKey:@"pushToken"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.userID = [decoder decodeObjectForKey:@"userID"];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.phone = [decoder decodeObjectForKey:@"phone"];

        self.createdAt = [decoder decodeObjectForKey:@"createdAt"];
        self.updatedAt = [decoder decodeObjectForKey:@"updatedAt"];
        self.sessionToken = [decoder decodeObjectForKey:@"sessionToken"];
        self.pushToken = [decoder decodeObjectForKey:@"pushToken"];
    }
    return self;
}



@end
