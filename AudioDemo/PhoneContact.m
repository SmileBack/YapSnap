//
//  PhoneContact.m
//  NightOut
//
//  Created by Jon Deokule on 6/25/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import "PhoneContact.h"

@implementation PhoneContact

/*
+ (RKObjectMapping *) objectMapping
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[PhoneContact class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"name" : @"name",
                                                  @"phone_number" : @"phoneNumber"}];
    
    return mapping;
}
*/

+ (PhoneContact *) phoneContactWithName:(NSString *)name contactID:(NSNumber *)contactID andPhoneNumber:(NSString *)phoneNumber
{
    PhoneContact *contact = [PhoneContact new];

    contact.name = name;
    contact.contactID = contactID;
    contact.phoneNumber = phoneNumber;
    
    return contact;
}

- (NSDictionary *) json
{
    return @{@"name": self.name,
             @"phone_number" : self.phoneNumber};
}

- (NSString *) sectionLetter
{
    if (self.name && self.name.length > 0) {
        return [self.name substringToIndex:1];
    }
    return @"";
}

@end
