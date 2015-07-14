//
//  RecentContact.h
//  YapSnap
//
//  Created by Jon Deokule on 1/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentContact : NSObject<NSCoding>

@property (nonatomic, strong) NSNumber *contactID; // Deprecated
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSDate *contactTime;

@end
