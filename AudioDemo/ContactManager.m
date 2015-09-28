//
//  ContactManager.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ContactManager.h"
#import "APAddressBook.h"
#import "APContact.h"

#define RECENT_CONTACTS_KEY @"yapsnap.RecentContacts"
#define RECENT_CONTACTS_CONTACT_PHONE @"contactPhone"
#define RECENT_CONTACTS_CONTACT_ID @"contactID"
#define RECENT_CONTACTS_CONTACT_TIME @"contactTime"

static ContactManager *sharedInstance;

@interface ContactManager()
@property (nonatomic, strong) NSMutableDictionary *phoneToContacts;

@property (nonatomic, strong) APAddressBook *addressBook;
@end

@implementation ContactManager

+ (ContactManager *) sharedContactManager
{
    if (!sharedInstance) {
        sharedInstance = [ContactManager new];
        sharedInstance.addressBook = [APAddressBook new];
        sharedInstance.addressBook.fieldsMask = APContactFieldFirstName | APContactFieldLastName | APContactFieldPhones | APContactFieldRecordID | APContactFieldCompositeName;
        sharedInstance.addressBook.sortDescriptors = @[
                                                       [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
                                                       [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]
                                                       ];
        sharedInstance.addressBook.filterBlock = ^BOOL(APContact *contact)
        {
            return contact.phones.count > 0;
        };
        
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
    return [APAddressBook access] == APAddressBookAccessGranted;
}

/**
 * Returns a phone number with numbers only starting with a 1
 */
- (NSString *) usNumberFromPhoneNumber:(NSString *)phoneNumber
{
    NSString *scrubbedPhone = [ContactManager stringPhoneNumber:phoneNumber];
    
    if ([scrubbedPhone hasPrefix:@"1"]) {
        return scrubbedPhone;
    }
    
    // TODO normalize for international numbers
    return [NSString stringWithFormat:@"1%@", scrubbedPhone];
}

- (PhoneContact *) contactForPhoneNumber:(NSString *)phoneNumber
{
    NSString *usNumber = [self usNumberFromPhoneNumber:phoneNumber];
    NSString *scrubbedNumber = [ContactManager stringPhoneNumber:phoneNumber];
    
    PhoneContact* contact = self.phoneToContacts[usNumber];
    if (!contact) {
        contact = self.phoneToContacts[scrubbedNumber];
    }
    
    return contact;
}

- (NSString *)nameForPhoneNumber:(NSString *)phoneNumber
{
    return [self contactForPhoneNumber:phoneNumber].name;
}

- (NSArray *) getAllContacts
{
    [self loadAllContacts];
    NSMutableArray *contacts = [NSMutableArray new];
    for (PhoneContact *contact in self.phoneToContacts.allValues) {
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

- (void) loadAllContacts
{
    __weak ContactManager *weakSelf = self;
    [self.addressBook loadContacts:^(NSArray *contacts, NSError *error) {
        NSMutableDictionary *idToContacts = [NSMutableDictionary dictionaryWithCapacity:contacts.count];
        NSMutableDictionary *phoneNumberContacts = [NSMutableDictionary dictionaryWithCapacity:contacts.count];

        for (APContact *contact in contacts) {
            NSLog(@"Contact: %@", contact);
            for (NSString *p in contact.phones) {
                NSString *phone = [ContactManager stringPhoneNumber:p];
                PhoneContact *phoneContact = [PhoneContact phoneContactWithName:contact.compositeName contactID:contact.recordID andPhoneNumber:phone];
                phoneNumberContacts[[self usNumberFromPhoneNumber:phoneContact.phoneNumber]] = phoneContact;
            }
        }

        weakSelf.phoneToContacts = phoneNumberContacts;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CONTACTS_LOADED object:nil];
    }];
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

+ (NSString *) stringPhoneNumber:(NSString *) originalString
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

#pragma mark - Recent Contact Stuff
- (void) addRecentContactAndUpdateOrder:(PhoneContact *)contact andTime:(NSDate *)time andSave:(BOOL)shouldSave
{
    if (!self.recentContacts)
        self.recentContacts = [NSMutableArray new];
    
    RecentContact *recent;
    // First if the person is already if our recent contact list we'll just update the time
    for (RecentContact *recentContact in self.recentContacts) {
        if ([recentContact.phoneNumber isEqual:contact.phoneNumber]) {
            recent = recentContact;
        }
    }

    // If they aren't in our recent contact list we'll make a new entry.
    if (!recent) {
        recent = [RecentContact new];
        recent.phoneNumber = contact.phoneNumber;
        [self.recentContacts addObject:recent];
    }
    recent.contactTime = time;
    
    // We've updated or added the contact.  Now sort.
    [self.recentContacts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        RecentContact *cont1 = obj1;
        RecentContact *cont2 = obj2;
        
        NSString *name1 = [self contactForPhoneNumber:cont1.phoneNumber].name;
        NSString *name2 = [self contactForPhoneNumber:cont2.phoneNumber].name;
        return [name1 compare:name2];
    }];
    
    if (shouldSave)
        [self saveRecentContacts];
}

- (void) sentYapTo:(NSArray *)contacts
{
    for (YSContact *contact in contacts) {
        if ([contact isKindOfClass:[PhoneContact class]]) {
            PhoneContact *phoneContact = (PhoneContact *)       contact;
            [self addRecentContactAndUpdateOrder:phoneContact andTime:[NSDate date] andSave:YES];
        }
    }
}

- (void) saveRecentContacts
{
    NSMutableArray *toSave = [NSMutableArray arrayWithCapacity:self.recentContacts.count];
    for (RecentContact *contact in self.recentContacts) {
        NSDictionary *dictToSave = @{RECENT_CONTACTS_CONTACT_PHONE: contact.phoneNumber,
                                     RECENT_CONTACTS_CONTACT_TIME: contact.contactTime};
        [toSave addObject:dictToSave];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:toSave forKey:RECENT_CONTACTS_KEY];
    [defaults synchronize];
}

- (void) loadRecentContacts
{
    NSArray *contacts = [[NSUserDefaults standardUserDefaults] arrayForKey:RECENT_CONTACTS_KEY];
    for (NSDictionary *recentContact in contacts) {
        NSString *phoneNumber = recentContact[RECENT_CONTACTS_CONTACT_PHONE];
        if (!phoneNumber && ![phoneNumber isKindOfClass:[NSString class]]) {
            // No phone number means this is an old form of RecentContact with no phone number.

            id contactID = recentContact[RECENT_CONTACTS_CONTACT_ID];
            APContact *apContact = [self.addressBook getContactByRecordID:contactID];
            if (apContact && apContact.phones.count == 1) {
                phoneNumber = apContact.phones[0];
            }
        }

        if (phoneNumber) {
            PhoneContact *contact = [self contactForPhoneNumber:phoneNumber];
            if (contact) {
                [self addRecentContactAndUpdateOrder:contact
                                             andTime:recentContact[RECENT_CONTACTS_CONTACT_TIME]
                                             andSave:(contact == contacts.lastObject)];
            }
        }
    }
}

- (void) syncRecentContacts
{
    if (!self.recentContacts || self.recentContacts.count == 0)
        return;
    
    NSMutableArray *contactsToSave = [NSMutableArray arrayWithCapacity:self.recentContacts.count];
    for (RecentContact *contact in self.recentContacts) {
        NSDictionary *c = @{RECENT_CONTACTS_CONTACT_PHONE: contact.phoneNumber,
                            RECENT_CONTACTS_CONTACT_TIME: contact.contactTime};
        [contactsToSave addObject:c];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:contactsToSave forKey:RECENT_CONTACTS_KEY];
    [defaults synchronize];
}

- (PhoneContact *) recentContactAtIndex:(NSInteger)index
{
    RecentContact *recent = self.recentContacts[index];
    return [self contactForPhoneNumber:recent.phoneNumber];
}


@end
