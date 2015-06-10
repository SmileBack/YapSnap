//
//  YSContact.m
//  YapSnap
//
//  Created by Jon Deokule on 2/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSContact.h"

@implementation YSContact

+ (YSContact *) contactWithName:(NSString *)name andPhoneNumber:(NSString *)phoneNumber
{
    YSContact *contact = [YSContact new];

    contact.name = name;
    [contact.phoneNumbers addObject:phoneNumber];

    return contact;
}

@end
