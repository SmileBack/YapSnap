//
//  UIViewController+Communication.m
//  NightOut
//
//  Created by Jon Deokule on 1/3/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import "UIViewController+Communication.h"
#import "AppDelegate.h"
#import <objc/runtime.h>
#import "MBProgressHUD.h"

@implementation UIViewController (Communication)

static void *ContactCompletionBlockKey;

- (void) setBlock:(ContactCompletionBlock)block
{
    objc_setAssociatedObject(self, &ContactCompletionBlockKey, block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) presentPeoplePickerWithBlock:(ContactCompletionBlock)block
{
    if (block)
        [self setBlock:block];

    ABPeoplePickerNavigationController *picker = [ABPeoplePickerNavigationController new];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PeoplePickerDelegate
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    //[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    [peoplePicker setDisplayedProperties:@[[NSNumber numberWithInt:kABPersonPhoneProperty]]];
    
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
    CFStringRef phone = ABMultiValueCopyValueAtIndex(multi, identifier);

    CFRelease(phone);
    
    //[peoplePicker dismissViewControllerAnimated:YES completion:^{
    //}];
    
    return NO;
}

- (void) callBlock:(BOOL)completed withRecipients:(NSArray *)recipients
{
    ContactCompletionBlock block = objc_getAssociatedObject(self, &ContactCompletionBlockKey);
    if (block) {
        block(completed, recipients);
    }
}



@end
