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

- (NSString *) stringPhoneNumber:(NSString *) originalString
{
    NSMutableString *strippedString = [NSMutableString
                                       stringWithCapacity:originalString.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:originalString];
    NSCharacterSet *numbers = [NSCharacterSet
                               characterSetWithCharactersInString:@"0123456789"];
    
    while ([scanner isAtEnd] == NO) {
        NSString *buffer;
        if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
            [strippedString appendString:buffer];
            
        } else {
            [scanner setScanLocation:([scanner scanLocation] + 1)];
        }
    }
    
    return strippedString;
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

- (NSString *) cleanLabel:(NSString *)label
{
    label = [label stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
    return [label stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
}

- (BOOL) isAuthorizedForContacts
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

#pragma Get Contacts
- (NSArray *) getAllContacts
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    NSMutableArray *contacts = [NSMutableArray new];
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );

        ABMutableMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        NSString *fullName = [self nameFromRef:person];

        for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            CFStringRef labelRef = ABMultiValueCopyLabelAtIndex(phones, i);
            
            if (labelRef) {
                NSString *label = [NSString stringWithString:(__bridge NSString *)(labelRef)];
                label = [self cleanLabel:label];
                
                CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phones, i);
                NSString *phone = [NSString stringWithString:(__bridge NSString *)(phoneRef)];
                phone = [self stringPhoneNumber:phone];
                
                PhoneContact *contact = [PhoneContact phoneContactWithName:fullName phoneLabel:label andPhoneNumber:phone];
                [contacts addObject:contact];
                
                CFRelease(phoneRef);
                CFRelease(labelRef);
            }
        }
    }
    
    [contacts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PhoneContact *contact1 = obj1;
        PhoneContact *contact2 = obj2;

        return [contact1.name compare:contact2.name];
    }];
    
    return contacts;
}

- (NSString *) nameFromRef:(ABRecordRef)person
{
    CFTypeRef firstNameRef = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *firstName = firstNameRef ? [NSString stringWithString:(__bridge NSString *)firstNameRef] : @"";
    
    CFTypeRef lastNameRef = ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *lastName = lastNameRef ? [NSString stringWithString:(__bridge NSString *)lastNameRef] : @"";
    
    NSString *fullName;
    if (lastName.length == 0) {
        fullName = firstName;
    } else {
        fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    }

    return fullName;
}


@end
