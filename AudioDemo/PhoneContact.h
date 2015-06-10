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

@property (nonatomic, strong) NSMutableArray *phoneLabels;
@property (nonatomic, strong) NSNumber *contactID;

@property (nonatomic, readonly) NSString *sectionLetter;

//+ (RKObjectMapping *) objectMapping;

+ (PhoneContact *) phoneContactWithName:(NSString *)name phoneLabels:(NSMutableArray *)allPhoneLabels andPhoneNumbers:(NSMutableArray *)allPhoneNumbers;

- (NSDictionary *) json;

@end
