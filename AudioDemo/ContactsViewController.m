//
//  ContactsViewController.m
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "ContactsViewController.h"
#import "UIViewController+Communication.h"
#import "MBProgressHUD.h"


@interface ContactsViewController ()
@property (nonatomic, strong) NSMutableSet *invitedPhones;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *filteredContacts;

@property (nonatomic, strong) NSMutableArray *selectedContacts;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *bottomView;

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
    
    
    //BACKGROUND COLOR OF SEARCH BAR
    //self.searchDisplayController.searchBar.barTintColor = [UIColor colorWithRed:232.0/255.0 green:237.0/255.0 blue:91.0/255.0 alpha:1.0f];
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

}

- (void) loadContacts
{
    __weak ContactsViewController *weakSelf = self;
    
    if (self.isAuthorizedForContacts) {
//        [[API sharedAPI] fetchInvitedFriends:^(NSMutableArray *array) {
//            for (PhoneContact *contact in array) {
//                [weakSelf.invitedPhones addObject:contact.phoneNumber];
//            }
//            [weakSelf.tableView reloadData];
//        }];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading contacts...";
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            weakSelf.contacts = [weakSelf getAllContacts];
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:YES];
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

- (NSMutableSet *) invitedPhones
{
    if (!_invitedPhones)
        _invitedPhones = [NSMutableSet set];
    
    return _invitedPhones;
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
    
    NSLog(@"No contact found for %@", number);
    return nil;
}

#pragma UITableViewDataSource
- (int) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.searchDisplayController.searchResultsTableView ? self.filteredContacts.count :  self.contacts.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhoneContact *contact = tableView == self.searchDisplayController.searchResultsTableView ? self.filteredContacts[indexPath.row] : self.contacts[indexPath.row];
    
    ContactSelectionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.nameLabel.text = contact.name;
    cell.phoneLabel.text = contact.phoneNumber;
    cell.typeLabel.text = contact.label;
    
    cell.selectionView.layer.cornerRadius = 8.0f;
    cell.selectionView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cell.selectionView.layer.borderWidth = 1.0f;
    cell.selectionView.backgroundColor = [self.selectedContacts containsObject:contact] ? [UIColor colorWithRed:245.0f/255.0f green:75.0f/255.0f blue:75.0f/255.0f alpha:1] : [UIColor clearColor];
    
    if ([self.invitedPhones containsObject:contact.phoneNumber]) {
        cell.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

#pragma mark UITableViewCellDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhoneContact *contact = tableView == self.searchDisplayController.searchResultsTableView ? self.filteredContacts[indexPath.row] : self.contacts[indexPath.row];
    
    if ([self.invitedPhones containsObject:contact.phoneNumber]) {
        NSString *message = [NSString stringWithFormat:@"You've already invited %@.  Try another friend!", contact.name];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Invited!"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        [self.selectedContacts removeObject:contact];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        return;
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

- (NSMutableArray *) selectableContacts {
    
    NSMutableArray *contacts = [NSMutableArray new];
    for (PhoneContact *contact in self.contacts) {
        if (![self.invitedPhones containsObject:contact.phoneNumber]) {
            [contacts addObject:contact];
        }
    }
    return contacts;
}


@end
