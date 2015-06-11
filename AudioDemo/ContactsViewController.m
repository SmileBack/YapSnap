//
//  ContactsViewController.m
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "ContactsViewController.h"
#import "ContactManager.h"
#import "UIViewController+Alerts.h"
#import "YapsViewController.h"
#import "YapBuilder.h"
#import "AddFriendsBuilder.h"
#import "UIViewController+MJPopupViewController.h"
#import "ContactsPopupViewController.h"

@interface ContactsViewController ()

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (nonatomic, strong) NSArray *allLetters;
@property (strong, nonatomic) IBOutlet UILabel *bottomViewLabel;
@property (strong, nonatomic) ContactsPopupViewController *contactsPopupVC;

// Map of section letter to contacts:  A : [cont1, cont2]
@property (nonatomic, strong) NSMutableDictionary *contactDict;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *keyboardVerticalSpace;

#define VIEWED_SPOTIFY_ALERT_KEY @"yaptap.ViewedSpotifyAlert"
#define VIEWED_CONTACTS_ONBOARDING_ALERT_KEY @"yaptap.ViewedContactsOnboardingAlertKey4"

@end

static NSString *CellIdentifier = @"Cell";


@implementation ContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Contacts Page"];
    
    self.bottomView.hidden = YES;
    
    CGRect frame = CGRectMake(0, 0, 160, 44);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    if (self.builder.builderType == BuilderTypeAddFriends) {
        label.text = @"Add Friends";
    } else {
        label.text = @"Send To...";
    }
    self.navigationItem.titleView = label;
    
    [self.tableView setSeparatorColor:[UIColor lightGrayColor]];
    self.selectedContacts = [NSMutableArray new];
    
    [self registerCellOnTableView:self.tableView];
    [self registerCellOnTableView:self.searchDisplayController.searchResultsTableView];
    
    [self loadContacts];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) { // if iOS 7
        self.edgesForExtendedLayout = UIRectEdgeNone; //layout adjustements
    }
        
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    if (self.builder.builderType == BuilderTypeAddFriends) {
        [self addCancelButton];
    }
    
    if ([self internetIsNotReachable]) {
        NSLog(@"Internet is not reachable");
    } else {
        NSLog(@"Internet is reachable");
    }
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    
    [self registerForKeyboardNotifications];
    
    [self setupNotifications];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.continueButton.userInteractionEnabled = YES;
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:DISMISS_CONTACTS_POPUP
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Dismiss Welcome Popup");
                        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                    }];
}

- (void) addCancelButton {
    UIImage* cancelModalImage = [UIImage imageNamed:@"WhiteDownArrow2.png"];
    UIButton *cancelModalButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [cancelModalButton setBackgroundImage:cancelModalImage forState:UIControlStateNormal];
    [cancelModalButton addTarget:self action:@selector(cancelPressed)
                forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc] initWithCustomView:cancelModalButton];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void) cancelPressed
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

#pragma mark - Onboarding Popup
- (void) showOnboardingPopup {
    self.contactsPopupVC = [[ContactsPopupViewController alloc] initWithNibName:@"ContactsPopupViewController" bundle:nil];
    [self presentPopupViewController:self.contactsPopupVC animationType:MJPopupViewAnimationFade];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_CONTACTS_ONBOARDING_ALERT_KEY];
}

#pragma mark - Contacts
- (NSArray *)allLetters
{
    if (!_allLetters) {
        _allLetters = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    }
    return _allLetters;
}

- (void) prepareContactDict
{
    self.contactDict = [NSMutableDictionary dictionaryWithCapacity:self.allLetters.count];
    for (NSString *letter in self.allLetters) {
        self.contactDict[letter] = [NSMutableArray new];
    }

    for (PhoneContact *c in self.contacts) {
        NSString *sectionName = c.sectionLetter;
        NSMutableArray *contacts = self.contactDict[sectionName];
        [contacts addObject:c];
    }
}

- (void) loadContacts
{
    __weak ContactsViewController *weakSelf = self;
    
    if ([ContactManager sharedContactManager].isAuthorizedForContacts) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.contacts = [[ContactManager sharedContactManager] getAllContacts];
            
            [weakSelf prepareContactDict];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        });
        if (self.builder.builderType == BuilderTypeYap) {
            double delay = 0.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!self.didViewContactsOnboardingAlert) {
                    [self showOnboardingPopup];
                }
            });
        }
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [weakSelf loadContacts];
                if (self.builder.builderType == BuilderTypeYap) {
                    double delay = 0.5;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!self.didViewContactsOnboardingAlert) {
                            [self showOnboardingPopup];
                        }
                    });
                }
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
                NSLog(@"Contacts permission denied");
                double delay = 1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Heads Up"
                                                                    message:@"You need to grant Contacts permission to send your yap. Go to your phone's Settings, click Privacy, and enable Contacts."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            }
        });
    }
}

- (void) registerCellOnTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"ContactSelectionCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
}

//- (PhoneContact *) contactForNumber:(NSString *)number
//{
//    
//    for (PhoneContact *contact in self.contacts) {
//        if ([contact.phoneNumber isEqualToString:number]) {
//            return contact;
//        }
//    }
//    
//    //NSLog(@"No contact found for %@", number);
//    return nil;
//}

#pragma UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            
            //NSLog(@"keys count:%lu", (unsigned long)[[[self filteredContactsAndNumbers] allKeys] count]);
            //NSLog(@"filtered ct:%lu", (unsigned long)self.filteredContacts.count);
            
            return [[[self filteredContactsWithPhoneNumbers:YES orPhoneLabelsInstead:NO] allKeys] count];
            //return self.filteredContacts.count;
        }else {
            return self.allLetters.count;
        }
    
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return [[[self filteredContactsWithPhoneNumbers:YES orPhoneLabelsInstead:NO] allKeys] count];
        }else {
            return 1 + self.allLetters.count;
        }
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            PhoneContact *person = self.filteredContacts[section];
            
            return [[[self filteredContactsWithPhoneNumbers:YES orPhoneLabelsInstead:NO] objectForKey:person.name]count];
        }

        NSString *letter = self.allLetters[section];
        NSArray *contactsInRow = self.contactDict[letter];
        return contactsInRow.count;
        
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return self.filteredContacts.count;
        }
        
        if (section == 0) {
            return [ContactManager sharedContactManager].recentContacts.count;
        } else {
            NSString *letter = self.allLetters[section - 1];
            NSArray *contactsInRow = self.contactDict[letter];
            return contactsInRow.count;
        }
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        PhoneContact *contact;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            contact = self.filteredContacts[indexPath.section];
            
        } else {
            NSString *letter = self.allLetters[indexPath.section];
            NSArray *contacts = self.contactDict[letter];
            contact = contacts[indexPath.row];
        }
        
        ContactSelectionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

        cell.nameLabel.text = contact.name;
        
        cell.phoneLabel.text = [[[self filteredContactsWithPhoneNumbers:YES orPhoneLabelsInstead:NO] objectForKey:contact.name]objectAtIndex:indexPath.row]; //....................................... sets the phone number label using the dictionary with array of numbers
        cell.typeLabel.text =  [[[self filteredContactsWithPhoneNumbers:NO orPhoneLabelsInstead:YES]objectForKey:contact.name]objectAtIndex:indexPath.row]; //........................................ sets the phone label using the dictionary with array of labels
        
        cell.selectionView.layer.cornerRadius = 8.0f;
        cell.selectionView.layer.borderColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR.CGColor : [UIColor lightGrayColor].CGColor;
        cell.selectionView.layer.borderWidth = 1.0f;
        cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR : [UIColor clearColor];
        
        cell.backgroundColor = [UIColor whiteColor];
        
        cell.nameLabel.font = [self.selectedContacts containsObject:contact] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
        
        return cell;
        
    } else {
        PhoneContact *contact;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            contact = self.filteredContacts[indexPath.row];
        } else if (indexPath.section == 0) {
            contact = [[ContactManager sharedContactManager] recentContactAtIndex:indexPath.row];
        } else {
            NSString *letter = self.allLetters[indexPath.section - 1];
            NSArray *contacts = self.contactDict[letter];
            contact = contacts[indexPath.row];
        }
        
        ContactSelectionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        
        cell.nameLabel.text = contact.name;
        
        //TODO: Make it check all numbers
        cell.phoneLabel.text = [contact.phoneNumbers objectAtIndex:0];
        cell.typeLabel.text = [contact.phoneLabels objectAtIndex:0];
        
        cell.selectionView.layer.cornerRadius = 8.0f;
        cell.selectionView.layer.borderColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR.CGColor : [UIColor lightGrayColor].CGColor;
        cell.selectionView.layer.borderWidth = 1.0f;
        cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR : [UIColor clearColor];
        
        cell.backgroundColor = [UIColor whiteColor];
        
        cell.nameLabel.font = [self.selectedContacts containsObject:contact] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
        
        return cell;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return nil;
        }
        
        NSString *letter = self.allLetters[section];
        NSArray *contacts = self.contactDict[letter];
        return contacts.count > 0 ? letter : nil;
        
        
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return nil;
        }
        
        if (section == 0) {
            if ([ContactManager sharedContactManager].recentContacts.count > 0) {
                return @"Recent Contacts";
            } else {
                return nil;
            }
        } else {
            NSString *letter = self.allLetters[section - 1];
            NSArray *contacts = self.contactDict[letter];
            return contacts.count > 0 ? letter : nil;
        }
    }
}

#pragma mark UITableViewCellDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        PhoneContact *contact;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            contact = self.filteredContacts[indexPath.row];
        } else {
            NSString *letter = self.allLetters[indexPath.section];
            NSArray *contacts = self.contactDict[letter];
            contact = contacts[indexPath.row];
        }
        
        if ([self.selectedContacts containsObject:contact]) {
            [self.selectedContacts removeObject:contact];
        } else {
            [self.selectedContacts addObject:contact];
        }
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        [self showOrHideBottomView];
        
        [self updateBottomViewText];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Selected Contact for Friend Request"];
    } else {
        PhoneContact *contact;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            contact = self.filteredContacts[indexPath.row];
        } else {
            if (indexPath.section == 0) {
                ContactManager *contactManager = [ContactManager sharedContactManager];
                RecentContact *recent = contactManager.recentContacts[indexPath.row];
                contact = [contactManager contactForContactID:recent.contactID];
            } else {
                NSString *letter = self.allLetters[indexPath.section - 1];
                NSArray *contacts = self.contactDict[letter];
                contact = contacts[indexPath.row];
            }
        }
        
        if ([self.selectedContacts containsObject:contact]) {
            [self.selectedContacts removeObject:contact];
        } else {
            [self.selectedContacts addObject:contact];
        }
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self showOrHideBottomView];
        
        [self updateBottomViewText];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Selected Contact for Yap"];
    }
}

- (void) showOrHideBottomView
{
    if (self.selectedContacts.count > 0) {
        self.bottomView.hidden = NO;
        [self.view bringSubviewToFront:self.bottomView];
    } else {
        self.bottomView.hidden = YES;
    }
}

- (void) updateBottomViewText
{
    if (self.builder.builderType == BuilderTypeYap) {
        if (self.selectedContacts.count == 1) {
            self.bottomViewLabel.text = [NSString stringWithFormat:@"%lu Recipient", (unsigned long)self.selectedContacts.count];
        } else {
            self.bottomViewLabel.text = [NSString stringWithFormat:@"%lu Recipients", (unsigned long)self.selectedContacts.count];
        }
    } else if (self.builder.builderType == BuilderTypeAddFriends) {
        if (self.selectedContacts.count == 1) {
            self.bottomViewLabel.text = [NSString stringWithFormat:@"%lu Request", (unsigned long)self.selectedContacts.count];
        } else {
            self.bottomViewLabel.text = [NSString stringWithFormat:@"%lu Requests", (unsigned long)self.selectedContacts.count];
        }
    }
}

#pragma mark - HELPER

// Method that will return a dictionary with the user's name
// and the telephone numbers associated with it
// the key is the contact name
// the object is an array with the  contact phone numbers
// allows you to chose if you want the phone numbers or the labels
-(NSMutableDictionary *)filteredContactsWithPhoneNumbers: (BOOL)withPhoneNumbers orPhoneLabelsInstead:(BOOL)phoneNumberLabels
{
    NSMutableDictionary *returnDict = [NSMutableDictionary new]; //................... dictionary to return
    
    if (withPhoneNumbers) //.............................................................. if they want phone numbers
        for( PhoneContact *contact in self.filteredContacts ) //.......................... loop through all the filtered contacts
            [returnDict setObject:contact.phoneNumbers forKey:contact.name]; //........... fill the dictionary with name / phone number
    else
        for( PhoneContact *contact in self.filteredContacts ) //.......................... loop through all the filtered contacts
            [returnDict setObject:contact.phoneLabels forKey:contact.name]; //............ fill the dictionary with name / phone number labels
    
    return returnDict; //................................................................. return the dictionary
}



#pragma mark - Keyboard
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    self.keyboardVerticalSpace.constant = kbSize.height;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    self.keyboardVerticalSpace.constant = 0;
}

- (IBAction) didTapContinueButton
{
    self.continueButton.userInteractionEnabled = NO;

    if ([self internetIsNotReachable]) {
        self.continueButton.userInteractionEnabled = YES;
        [self showNoInternetAlert];
    } else {
        self.builder.contacts = self.selectedContacts;
        
        [self processBuilder];

        self.continueButton.userInteractionEnabled = YES;
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"YapsViewControllerSegue" isEqualToString:segue.identifier]) {
        NSArray *pendingYaps = sender;
        YapsViewController *vc = segue.destinationViewController;
        vc.pendingYaps = pendingYaps;
        vc.comingFromContactsOrCustomizeYapPage = YES;
    }
}

#pragma mark - Continue Actions
- (void) processBuilder
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        [self sendAddFriendsBuilder];
    } else if (self.builder.builderType == BuilderTypeYap) {
        [self sendYapBuilder];
    }
}

- (void) sendAddFriendsBuilder
{
    __weak ContactsViewController *weakSelf = self;

    AddFriendsBuilder *addFriendsBuilder = (AddFriendsBuilder *) self.builder;
    
    [[API sharedAPI] addFriends:addFriendsBuilder
                       withCallback:^(BOOL success, NSError *error) {
                           if (success) {
                               Mixpanel *mixpanel = [Mixpanel sharedInstance];
                               [mixpanel track:@"Sent Friend Request"];
                               
                               [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                               
                               double delay = .3;
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                   [self showFriendsSuccessAlert];
                               });
                           } else {
                               // uh oh spaghettios
                               // TODO: tell the user something went wrong
                           }
                       }];
    
    [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendYapBuilder
{
    __weak ContactsViewController *weakSelf = self;

    YapBuilder *yapBuilder = (YapBuilder *)self.builder;
    
    NSArray *pendingYaps =
    [[API sharedAPI] sendYapBuilder:yapBuilder
                       withCallback:^(BOOL success, NSError *error) {
                           if (success) {
                               [[ContactManager sharedContactManager] sentYapTo:weakSelf.selectedContacts];
                           } else {
                               // uh oh spaghettios
                               // TODO: tell the user something went wrong
                           }
                       }];
    
    [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:pendingYaps];
}

#pragma mark - UISearchDisplayDelegate
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self registerCellOnTableView:controller.searchResultsTableView];
}

- (void) searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSPredicate *firstNamePredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", searchText];
    NSPredicate *fullPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[firstNamePredicate]];
    self.filteredContacts = [self.contacts filteredArrayUsingPredicate:fullPredicate];
}

#pragma mark - Spotify Alert Methods

- (void) viewedSpotifyAlert
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_SPOTIFY_ALERT_KEY];
}

- (BOOL) didViewSpotifyAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_SPOTIFY_ALERT_KEY];
}

- (BOOL) didViewContactsOnboardingAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_CONTACTS_ONBOARDING_ALERT_KEY];
}

- (void) showFriendsSuccessAlert
{
    if (self.selectedContacts.count == 1) {
        YSContact *selectedContact = self.selectedContacts[0];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend Request Sent"
                                                        message:[NSString stringWithFormat:@"%@ will be added to your friends once he/she accepts!", selectedContact.name]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend Requests Sent"
                                                        message:@"They'll be added to your friends once they accept!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

@end
