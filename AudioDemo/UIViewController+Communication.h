//
//  UIViewController+Communication.h
//  NightOut
//
//  Created by Jon Deokule on 1/3/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PhoneContact.h"


typedef void (^ContactCompletionBlock)(BOOL completed, NSArray *recipients);

@interface UIViewController (Communication) <ABPeoplePickerNavigationControllerDelegate>

- (void) presentPeoplePickerWithBlock:(ContactCompletionBlock)block;

@end
