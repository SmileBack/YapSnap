//
//  ContactsViewController.m
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "ContactsViewController.h"
#import "MBProgressHUD.h"
#import "ContactManager.h"

@interface ContactsViewController ()

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (nonatomic, strong) NSArray *allLetters;

// Map of section letter to contacts:  A : [cont1, cont2]
@property (nonatomic, strong) NSMutableDictionary *contactDict;
@end

static NSString *CellIdentifier = @"Cell";


@implementation ContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bottomView.hidden = YES;
    self.navigationItem.title = @"Send To...";
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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    if ([self internetIsNotReachable]) {
        NSLog(@"Internet is not reachable");
    } else {
        NSLog(@"Internet is reachable");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.continueButton.userInteractionEnabled = YES;
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) showNoInternetAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                    message:@"Please connect to the internet and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
        //MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        //hud.labelText = @"Loading contacts...";
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.contacts = [[ContactManager sharedContactManager] getAllContacts];
            
            [weakSelf prepareContactDict];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[hud hide:YES];
                [weakSelf.tableView reloadData];
            });
        });
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [weakSelf loadContacts];
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }else {
        return 1 + self.allLetters.count;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
    NSLog(@"Contact: %@", contact.name);
    NSLog(@"IndexPath: section %d   row %d", indexPath.section, indexPath.row);
    ContactSelectionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    cell.nameLabel.text = contact.name;
    cell.phoneLabel.text = contact.phoneNumber;
    cell.typeLabel.text = contact.label;
    
    cell.selectionView.layer.cornerRadius = 8.0f;
    cell.selectionView.layer.borderColor = [self.selectedContacts containsObject:contact] ? [UIColor colorWithRed:245.0f/255.0f green:75.0f/255.0f blue:75.0f/255.0f alpha:1].CGColor : [UIColor lightGrayColor].CGColor;
    cell.selectionView.layer.borderWidth = 1.0f;
    cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? [UIColor colorWithRed:245.0f/255.0f green:75.0f/255.0f blue:75.0f/255.0f alpha:1] : [UIColor clearColor];
    
    cell.backgroundColor = [UIColor whiteColor];
    
    cell.nameLabel.font = [self.selectedContacts containsObject:contact] ? [UIFont fontWithName:@"Helvetica-Bold" size:19] : [UIFont fontWithName:@"Helvetica" size:19];
    
        return cell;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
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

#pragma mark UITableViewCellDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

- (void) showOrHideBottomView
{
    if (self.selectedContacts.count > 0) {
        self.bottomView.hidden = NO;
        [self.tableView setFrame:CGRectMake(0, self.searchDisplayController.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.bottomView.frame.size.height - self.searchDisplayController.searchBar.frame.size.height)];
    } else {
        self.bottomView.hidden = YES;
        [self.tableView setFrame:CGRectMake(0, self.searchDisplayController.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchDisplayController.searchBar.frame.size.height)];
    }
        
}

- (IBAction) didTapContinueButton
{
    self.continueButton.userInteractionEnabled = NO;
    
    if ([self internetIsNotReachable]) {
        [self showNoInternetAlert];
        self.continueButton.userInteractionEnabled = YES;
    } else {
        __weak ContactsViewController *weakSelf = self;
        
        self.yapBuilder.contacts = self.selectedContacts;
        
        [[API sharedAPI] sendYap:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.selectedContacts];
                            [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:self];
                        } else {
                            // uh oh spaghettios
                            // TODO: tell the user something went wrong
                            self.continueButton.userInteractionEnabled = YES;
                        }
                    }];
    }
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
    NSPredicate *fullPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[firstNamePredicate]];//, lastNamePredicate]];
    self.filteredContacts = [self.contacts filteredArrayUsingPredicate:fullPredicate];
}

@end
