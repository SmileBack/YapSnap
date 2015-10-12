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
#import "RecentContact.h"

#define NOTIFICATION_CONTACTS_LOADED @"com.yapsnap.ContactsLoaded"

@interface ContactManager : NSObject

- (NSArray *) getAllContacts;

+ (ContactManager *) sharedContactManager;
+ (NSString *) stringPhoneNumber:(NSString *) originalString;

- (BOOL) isAuthorizedForContacts;

- (NSString *) nameForPhoneNumber:(NSString *)phoneNumber;
- (PhoneContact *) contactForPhoneNumber:(NSString *)phoneNumber;
- (PhoneContact *) recentContactAtIndex:(NSInteger)index;

// THIS IS A HACK
@property (assign, nonatomic) BOOL sleep;

#pragma mark - Recent Contact Stuff
@property (nonatomic, strong) NSMutableArray *recentContacts;
- (void) sentYapTo:(NSArray *)contacts;
@end
