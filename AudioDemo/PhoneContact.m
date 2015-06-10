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

+ (PhoneContact *) phoneContactWithName:(NSString *)name phoneLabels:(NSMutableArray *)allPhoneLabels andPhoneNumbers:(NSMutableArray *)allPhoneNumbers
{
    PhoneContact *contact = [PhoneContact new];

    contact.name = name;
    contact.phoneLabels = allPhoneLabels;
    contact.phoneNumbers = allPhoneNumbers;
    
   // NSLog(@"InPhoneContact: Phone Number: %@", contact.phoneNumbers );
   // NSLog(@"InPhoneContact: Phone Labels: %@", contact.phoneLabels );
    

    
    return contact;
}

- (NSDictionary *) json
{
    if ([self.phoneNumbers count] > 1) //............................................................................................. if there are more than one phone number for the contact
    {
        NSMutableDictionary *rtnDictionary = [[NSMutableDictionary alloc]initWithCapacity:[self.phoneNumbers count] + 1]; //.......... create a dictionary with length of all phone numbers + the name
        
        [rtnDictionary setValue:@"name" forKey:self.name]; //......................................................................... set the inial value to the name
        
        for (int i = 1; i < [self.phoneNumbers count]; i++) //........................................................................ loop through each phone number
            [rtnDictionary setValue:[NSString stringWithFormat:@"phone_number_%i", i]
                             forKey:[self.phoneNumbers objectAtIndex:i] ]; //......................................................... add the phone number to the dictionary
        
        return rtnDictionary; //...................................................................................................... return the dictionary
    }
    else
    {
        return @{@"name": self.name,
                 @"phone_number_0" : [self.phoneNumbers objectAtIndex:0]};
    }
}

- (NSString *) sectionLetter
{
    if (self.name && self.name.length > 0) {
        return [self.name substringToIndex:1];
    }
    return @"";
}

@end
