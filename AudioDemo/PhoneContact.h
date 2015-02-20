//
//  PhoneContact.h
//  NightOut
//
//  Created by Jon Deokule on 6/25/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSContact.h"

@interface PhoneContact : YSContact

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSNumber *contactID;

@property (nonatomic, readonly) NSString *sectionLetter;

//+ (RKObjectMapping *) objectMapping;

+ (PhoneContact *) phoneContactWithName:(NSString *)name phoneLabel:(NSString *)label andPhoneNumber:(NSString *)phoneNumber;

- (NSDictionary *) json;

@end
