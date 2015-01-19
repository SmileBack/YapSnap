//
//  ContactManager.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ContactManager.h"

static ContactManager *sharedInstance;

@interface ContactManager()
@property (nonatomic, strong) NSArray *contacts;
@end

@implementation ContactManager

+ (ContactManager *) sharedContactManager
{
    if (!sharedInstance) {
        sharedInstance = [ContactManager new];
        if (sharedInstance.isAuthorizedForContacts) {
            [sharedInstance loadAllContacts];
        }
    }
    return sharedInstance;
}

- (BOOL) isAuthorizedForContacts
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (NSString *)nameForPhoneNumber:(NSString *)phoneNumber
{
    NSString *scrubbedPhone = [self stringPhoneNumber:phoneNumber];
    for (PhoneContact *contact in self.contacts) {
        if ([contact.phoneNumber isEqualToString:scrubbedPhone]) {
            return contact.name;
        }
    }
    return nil;
}

- (NSArray *) getAllContacts
{
    [self loadAllContacts];
    return self.contacts;
}

- (void) loadAllContacts
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
    
    self.contacts = contacts;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CONTACTS_LOADED object:nil];
}

#pragma mark - Helpers

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

- (NSString *) cleanLabel:(NSString *)label
{
    label = [label stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
    return [label stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
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



@end
