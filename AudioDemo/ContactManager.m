//
//  ContactManager.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ContactManager.h"
#import "RecentContact.h"

#define RECENT_CONTACTS_KEY @"yapsnap.RecentContacts"
#define RECENT_CONTACTS_CONTACT_ID @"contactID"
#define RECENT_CONTACTS_CONTACT_TIME @"contactTime"

static ContactManager *sharedInstance;

@interface ContactManager()
@property (nonatomic, strong) NSMutableDictionary *contacts;
@end

@implementation ContactManager

+ (ContactManager *) sharedContactManager
{
    if (!sharedInstance) {
        sharedInstance = [ContactManager new];
        if (sharedInstance.isAuthorizedForContacts) {
            [sharedInstance loadAllContacts];
            [sharedInstance loadRecentContacts];
        }
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:sharedInstance selector:@selector(syncRecentContacts) name:UIApplicationWillTerminateNotification object:nil];
        [center addObserver:sharedInstance selector:@selector(syncRecentContacts) name:UIApplicationWillResignActiveNotification object:nil];
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
    for (PhoneContact *contact in [self getAllContacts]) {
        if ([contact.phoneNumber isEqualToString:scrubbedPhone]) {
            return contact.name;
        }
    }
    return nil;
}

- (PhoneContact *) contactForPhoneNumber:(NSString *)phoneNumber
{
    NSString *phone = [self stringPhoneNumber:phoneNumber];
    for (PhoneContact *contact in self.contacts.allValues) {
        if ([phone isEqualToString:contact.phoneNumber]) {
            return contact;
        }
    }
    return nil;
}

- (NSArray *) getAllContacts
{
    [self loadAllContacts];
    NSMutableArray *contacts = [NSMutableArray new];
    for (PhoneContact *contact in self.contacts.allValues) {
        if (contact.name && contact.name.length > 0) {
            [contacts addObject:contact];
        }
    }
    return [contacts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PhoneContact *contact1 = obj1;
        PhoneContact *contact2 = obj2;

        return [contact1.name compare:contact2.name];
    }];
}

- (PhoneContact *) contactForContactID:(NSNumber *)contactID
{
    return self.contacts[contactID];
}

- (PhoneContact *) recentContactAtIndex:(NSInteger)index
{
    RecentContact *recent = self.recentContacts[index];
    return [self contactForContactID:recent.contactID];
}

- (void) loadAllContacts
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    NSMutableDictionary *contacts = [NSMutableDictionary new];
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        
        ABMutableMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        NSString *fullName = [self nameFromRef:person];
        ABRecordID recordID = ABRecordGetRecordID(person);
        
        for (CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            CFStringRef labelRef = ABMultiValueCopyLabelAtIndex(phones, i);
            
            if (labelRef) {
                NSString *label = [NSString stringWithString:(__bridge NSString *)(labelRef)];
                label = [self cleanLabel:label];
                
                CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(phones, i);
                NSString *phone = [NSString stringWithString:(__bridge NSString *)(phoneRef)];
                phone = [self stringPhoneNumber:phone];
                
                PhoneContact *contact = [PhoneContact phoneContactWithName:fullName phoneLabel:label andPhoneNumber:phone];
                contact.contactID = [NSNumber numberWithInt:recordID];
                contacts[contact.contactID] = contact;
                
                CFRelease(phoneRef);
                CFRelease(labelRef);
            }
        }
    }

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

- (PhoneContact *) contactForId:(NSNumber *)contactID
{
    @try {
        id contact = self.contacts[contactID];
        return ([contact isKindOfClass:[PhoneContact class]]) ? contact : nil;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

#pragma mark - Recent Contact Stuff
- (void) addRecentContactAndUpdateOrder:(PhoneContact *)contact andTime:(NSDate *)time
{
    if (!self.recentContacts)
        self.recentContacts = [NSMutableArray new];

    RecentContact *recent;
    // First if the person is already if our recent contact list we'll just update the time
    for (RecentContact *recentContact in self.recentContacts) {
        if ([recentContact.contactID isEqualToNumber:contact.contactID]) {
            recent = recentContact;
        }
    }

    // If they aren't in our recent contact list we'll make a new entry.
    if (!recent) {
        recent = [RecentContact new];
        recent.contactID = contact.contactID;
        [self.recentContacts addObject:recent];
    }
    recent.contactTime = time;

    // We've updated or added the contact.  Now sort.
    [self.recentContacts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        RecentContact *cont1 = obj1;
        RecentContact *cont2 = obj2;
        
        NSString *name1 = [self contactForId:cont1.contactID].name;
        NSString *name2 = [self contactForId:cont2.contactID].name;
        return [name1 compare:name2];
    }];
}

- (void) sentYapTo:(NSArray *)contacts
{
    for (PhoneContact *contact in contacts) {
        [self addRecentContactAndUpdateOrder:contact andTime:[NSDate date]];
    }
}

- (void) loadRecentContacts
{
    NSArray *contacts = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_CONTACTS_KEY];
    for (NSDictionary *recentContact in contacts) {
        NSNumber *contactID = recentContact[RECENT_CONTACTS_CONTACT_ID];
        PhoneContact *contact = [self contactForId:contactID];
        NSDate *time = recentContact[RECENT_CONTACTS_CONTACT_TIME];
        if (contact) {
            [self addRecentContactAndUpdateOrder:contact andTime:time];
        }
    }
}

- (void) syncRecentContacts
{
    if (!self.recentContacts || self.recentContacts.count == 0)
        return;

    NSMutableArray *contactsToSave = [NSMutableArray arrayWithCapacity:self.recentContacts.count];
    for (RecentContact *contact in self.recentContacts) {
        NSDictionary *c = @{RECENT_CONTACTS_CONTACT_ID: contact.contactID,
                            RECENT_CONTACTS_CONTACT_TIME: contact.contactTime};
        [contactsToSave addObject:c];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:contactsToSave forKey:RECENT_CONTACTS_KEY];
    [defaults synchronize];
}



@end
