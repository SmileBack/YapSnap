//
//  PhoneContact.h
//  NightOut
//
//  Created by Jon Deokule on 6/25/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhoneContact : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSNumber *contactID;

//+ (RKObjectMapping *) objectMapping;

+ (PhoneContact *) phoneContactWithName:(NSString *)name phoneLabel:(NSString *)label andPhoneNumber:(NSString *)phoneNumber;

- (NSDictionary *) json;

@end
