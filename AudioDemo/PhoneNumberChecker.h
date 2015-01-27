//
//  PhoneNumberChecker.h
//  YapSnap
//
//  Created by Dan Berenholtz on 9/18/12.
//  Copyright (c) 2012 WhoWentOut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhoneNumberChecker : NSObject

- (BOOL) isPhoneNumberValid:(NSString *)phoneNumber;

@end
