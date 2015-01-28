//
//  ContactManager.h
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PhoneContact.h"

#define NOTIFICATION_CONTACTS_LOADED @"com.yapsnap.ContactsLoaded"

@interface ContactManager : NSObject

- (NSArray *) getAllContacts;

+ (ContactManager *) sharedContactManager;

- (BOOL) isAuthorizedForContacts;

- (NSString *) nameForPhoneNumber:(NSString *)phoneNumber;
- (PhoneContact *) contactForContactID:(NSNumber *)contactID;
- (PhoneContact *) recentContactAtIndex:(NSInteger)index;

#pragma mark - Recent Contact Stuff
@property (nonatomic, strong) NSMutableArray *recentContacts;
- (void) sentYapTo:(NSArray *)contacts;
@end
