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
#import <MessageUI/MessageUI.h>
#import "UIAlertView+Blocks.h"
#import "NextButton.h"

@interface ContactsViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NextButton *continueButton;
@property (nonatomic, strong) NSArray *allLetters;
@property (strong, nonatomic) IBOutlet UILabel *bottomViewLabel;
@property (strong, nonatomic) ContactsPopupViewController *contactsPopupVC;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *continueButtonRightConstraint;

// Map of section letter to contacts:  A : [cont1, cont2]
@property (nonatomic, strong) NSMutableDictionary *contactDict;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *keyboardVerticalSpace;

#define VIEWED_CONTACTS_ONBOARDING_ALERT_KEY @"yaptap.ViewedContactsOnboardingAlertKey10"

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
    self.titleLabel = [[UILabel alloc] initWithFrame:frame];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    if (self.builder.builderType == BuilderTypeAddFriends) {
        self.titleLabel.text = @"Add Friends";
    } else {
        self.titleLabel.text = @"Send To...";
    }
    self.navigationItem.titleView = self.titleLabel;
    
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
    
    [self.continueButton startToPulsate];
    
    // Convert YapBuilder contacts to phone contacts
    if (self.builder.contacts.count > 0) {
        if (self.builder.contacts.count == 1) {
            if (![self.builder.contacts[0] isKindOfClass:[PhoneContact class]]) {
                YSContact *ysContact = self.builder.contacts[0];
                NSString *ysContactPhone = ysContact.phoneNumber;
                NSLog(@"ysContactPhone: %@", ysContactPhone);
                
                PhoneContact *phoneContact = [[ContactManager sharedContactManager] contactForPhoneNumber:ysContactPhone];
                NSLog(@"phoneContactPhone: %@", phoneContact.phoneNumber);
                
                if (phoneContact) {
                    [self.selectedContacts addObject: phoneContact];
                } else {
                    [self.selectedContacts addObject: self.builder.contacts[0]];
                }
            } else {
                [self.selectedContacts addObject: self.builder.contacts[0]];
            }
        } else {
            if (!self.builder.contacts) {
                self.builder.contacts = @[ ];
            }
            NSArray *contactsArray = [self.selectedContacts arrayByAddingObjectsFromArray:self.builder.contacts];
            self.selectedContacts = [NSMutableArray arrayWithArray:contactsArray];
        }

        [self showOrHideBottomView];
        [self updateBottomViewText];
        [self updateTitleLabel];
        
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismissViewControllerDuringDoubleTapToReplyFlow)];
        [self.navigationItem setLeftBarButtonItem:cancel];
    };
    
    [self setupConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.continueButton.userInteractionEnabled = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
    
//    [center addObserverForName:NOTIFICATION_CONTACTS_LOADED
//                        object:nil
//                         queue:nil
//                    usingBlock:^(NSNotification *note) {
//                        [self.tableView reloadData];
//                    }];
}

- (void) setupConstraints {
    if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
        self.continueButtonRightConstraint.constant = -128;
    } else if (IS_IPHONE_6_SIZE) {
        self.continueButtonRightConstraint.constant = -150;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.continueButtonRightConstraint.constant = -170;
    }
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
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            weakSelf.contacts = [[ContactManager sharedContactManager] getAllContacts];
                        
            [weakSelf prepareContactDict];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
        //    });
        });
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // SHOW ONBOARDING POPUP
                if (self.builder.builderType == BuilderTypeYap) {
                    double delay = 0.1;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!self.didViewContactsOnboardingAlert) {
                            [self showOnboardingPopup];
                            NSLog(@"SHOWED ONBOARDING POPUP");
                        }
                    });
                }
                
                // THIS NEXT LINE IS A HACK!!!!!!!!!!!
                [ContactManager sharedContactManager].sleep = YES;
                
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

- (PhoneContact *) contactForNumber:(NSString *)number
{
    
    for (PhoneContact *contact in self.contacts) {
        if ([contact.phoneNumber isEqualToString:number]) {
            return contact;
        }
    }
    
    //NSLog(@"No contact found for %@", number);
    return nil;
}

#pragma UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return 1;
        }else {
            return self.allLetters.count;
        }
    
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return 1;
        }else {
            return 1 + self.allLetters.count;
        }
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.builder.builderType == BuilderTypeAddFriends) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return self.filteredContacts.count;
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
            contact = self.filteredContacts[indexPath.row];
        } else {
            NSString *letter = self.allLetters[indexPath.section];
            NSArray *contacts = self.contactDict[letter];
            contact = contacts[indexPath.row];
        }
        
        ContactSelectionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

        cell.nameLabel.text = contact.name;
        cell.phoneLabel.text = contact.phoneNumber;
        
        cell.selectionView.layer.cornerRadius = 8.0f;
        cell.selectionView.layer.borderColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR.CGColor : [UIColor lightGrayColor].CGColor;
        cell.selectionView.layer.borderWidth = 1.0f;
        cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR : [UIColor clearColor];
        
        cell.backgroundColor = [UIColor whiteColor];
        
        cell.nameLabel.font = [self.selectedContacts containsObject:contact] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
        
        return cell;
        
    } else {
        PhoneContact *contact;
        
        //NSLog(@"contact: %@", contact);
        //NSLog(@"contact name: %@", contact.name);
        //NSLog(@"contact phone: %@", contact.phoneNumber);
        
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
        cell.phoneLabel.text = contact.phoneNumber;
        cell.typeLabel.text = contact.label;
        
        cell.selectionView.layer.cornerRadius = 8.0f;
        
        NSArray *selectedContactsPhoneNumbers = [self.selectedContacts valueForKeyPath:@"phoneNumber"];
        cell.selectionView.layer.borderColor = [selectedContactsPhoneNumbers containsObject:contact.phoneNumber] ? THEME_RED_COLOR.CGColor : [UIColor lightGrayColor].CGColor;
        cell.selectionView.backgroundColor = [selectedContactsPhoneNumbers containsObject:contact.phoneNumber] ? THEME_RED_COLOR : [UIColor clearColor];
        cell.nameLabel.font = [selectedContactsPhoneNumbers containsObject:contact.phoneNumber] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
        
        /*
        cell.selectionView.layer.borderColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR.CGColor : [UIColor lightGrayColor].CGColor;
        cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? THEME_RED_COLOR : [UIColor clearColor];
        cell.nameLabel.font = [self.selectedContacts containsObject:contact] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
         */

        cell.selectionView.layer.borderWidth = 1.0f;
        
        cell.backgroundColor = [UIColor whiteColor];
        
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
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        [self showOrHideBottomView];
        [self updateBottomViewText];
        [self updateTitleLabel];
        
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
                contact = [contactManager contactForPhoneNumber:recent.phoneNumber];
            } else {
                NSString *letter = self.allLetters[indexPath.section - 1];
                NSArray *contacts = self.contactDict[letter];
                contact = contacts[indexPath.row];
            }
        }
        
        NSArray *selectedContactsPhoneNumbers = [self.selectedContacts valueForKeyPath:@"phoneNumber"];
        if ([selectedContactsPhoneNumbers containsObject:contact.phoneNumber]) {
            // locate object
            NSInteger count = [self.selectedContacts count];
            for (NSInteger index = (count - 1); index >= 0; index--) {
                PhoneContact *phoneContact = self.selectedContacts[index];
                if ([phoneContact.phoneNumber isEqualToString:contact.phoneNumber]) {
                    [self.selectedContacts removeObject:phoneContact];
                }
            }
        } else {
            [self.selectedContacts addObject:contact];
        }
        
        /*
        if ([self.selectedContacts containsObject:contact]) {
            [self.selectedContacts removeObject:contact];
        } else {
            [self.selectedContacts addObject:contact];
        }
         */
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [self showOrHideBottomView];
        [self updateBottomViewText];
        [self updateTitleLabel];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Selected Contact for Yap"];
    }
}

-( void) updateTitleLabel {
    if (self.selectedContacts.count > 0) {
        self.titleLabel.text = @"Add Recipients";
        self.navigationItem.titleView = self.titleLabel;
    } else {
        self.titleLabel.text = @"Send to...";
        self.navigationItem.titleView = self.titleLabel;
    }
}

- (void) showOrHideBottomView {
    if (self.selectedContacts.count > 0) {
        self.bottomView.hidden = NO;
        [self.view bringSubviewToFront:self.bottomView];
    } else {
        self.bottomView.hidden = YES;
    }
}

- (void) updateBottomViewText {
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
    
    [[API sharedAPI] sendFriendRequests:addFriendsBuilder
                       withCallback:^(BOOL success, NSError *error) {
                           if (success) {
                               Mixpanel *mixpanel = [Mixpanel sharedInstance];
                               [mixpanel track:@"Sent Friend Request"];
                               
                               [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
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
                               [[NSNotificationCenter defaultCenter] postNotificationName:DID_SEND_YAP_NOTIFICATION object:nil];
                               [[ContactManager sharedContactManager] sentYapTo:weakSelf.selectedContacts];
                           } else {
                               NSLog(@"Error Sending Yap: %@", error);
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

- (BOOL) didViewContactsOnboardingAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_CONTACTS_ONBOARDING_ALERT_KEY];
}

- (void) dismissViewControllerDuringDoubleTapToReplyFlow {
    [self.delegate updateYapBuilderContacts:self.selectedContacts];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
