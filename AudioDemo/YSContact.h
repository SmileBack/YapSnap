//
//  YSContact.h
//  YapSnap
//
//  Created by Jon Deokule on 2/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSContact : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *phoneNumber;

+ (YSContact *) contactWithName:(NSString *)name andPhoneNumber:(NSString *)phoneNumber;

@end
