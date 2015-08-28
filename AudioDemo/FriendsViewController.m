//
//  FriendsViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 2/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "FriendsViewController.h"
#import "API.h"
#import "UserCell.h"
#import "ContactsViewController.h"
#import "AudioCaptureViewController.h"
#import "ContactManager.h"
#import <MessageUI/MessageUI.h>

#define CELL_COLLAPSED @"Collapsed Cell"
#define CELL_EXPANDED @"Expanded Cell"

#define HEIGHT_COLLAPSED 50.0f
#define HEIGHT_EXPANDED 100.0f


@interface FriendsViewController() <MFMessageComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *myTopFriends;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSMutableDictionary *topFriendMap; //Friend ID :: Top friends array
@property (strong, nonatomic) IBOutlet UIView *addFriendsView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, strong) NSString *friendOneLabelString;
@property (strong, nonatomic) IBOutlet UIView *largeAddFriendsButton;
@property (strong, nonatomic) YTUnregisteredUserSMSInviter *unregisteredUserSMSInviter;
@property (nonatomic, strong) YSUser *selectedFriend;
@property (assign, nonatomic) BOOL replyWithVoice;
//@property (assign, nonatomic) BOOL smsAlertWasAlreadyPrompted;


- (IBAction) didTapLargeAddFriendsButton;

@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Friends Page"];
    
    self.unregisteredUserSMSInviter = [[YTUnregisteredUserSMSInviter alloc] init];
    self.unregisteredUserSMSInviter.delegate = self;

    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:0.99]];

    CGRect frame = CGRectMake(0, 0, 160, 44);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Friends";
    self.navigationItem.titleView = label;
    
    self.friendOneLabelString = @"Loading...";
    
    __weak FriendsViewController *weakSelf = self;
    [[API sharedAPI] friends:^(NSArray *friends, NSError *error) {
        if (error) {
            double delay = 0.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Loading Friends!"];
                
            });
        } else {
            if (friends.count > 2) {
                self.myTopFriends = [friends subarrayWithRange:NSMakeRange(0, 3)];
            } else if (friends.count > 0) {
                self.myTopFriends = friends;
            }
            
            if (friends.count < 4) {
                self.largeAddFriendsButton.hidden = NO;
                self.addFriendsView.hidden = NO;
            }

            weakSelf.friends = [friends sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                YSUser *user1 = obj1;
                YSUser *user2 = obj2;
                return [user1.displayName compare:user2.displayName];
            }];
            if (friends.count == 0) {
                self.friendOneLabelString = @"No top friends";
            }
            [weakSelf.tableView reloadData];
        }
    }];
    
    [self getSelfAndUpdateScore];
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    
    [self setupDoubleTap];
    
    [self setupNotifications];
    
    self.largeAddFriendsButton.layer.cornerRadius = 8;
    self.largeAddFriendsButton.layer.borderWidth = 1;
    self.largeAddFriendsButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self addCancelButton];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
    //This is part of a hack to prevent multiple popups from showing
    //self.smsAlertWasAlreadyPrompted = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //This is a hack to prevent multiple popups from showing
    //self.smsAlertWasAlreadyPrompted = YES;
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserverForName:FRIENDS_YAP_SENT_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self dismissViewControllerAnimated:NO completion:nil];
                    }];
    
     [center addObserverForName:NOTIFICATION_FRIEND_REQUEST_SENT
                         object:nil
                          queue:nil
                     usingBlock:^(NSNotification *note) {
                         NSLog(@"Display invite popup");
                            
                         //if (!self.smsAlertWasAlreadyPrompted) {
                            if ([note.userInfo[@"yaps"] isKindOfClass:[NSArray class]] && [MFMessageComposeViewController canSendText]) {
                                NSArray* yaps = (NSArray*)note.userInfo[@"yaps"];
                                [self.unregisteredUserSMSInviter promptSMSAlertForFriendRequestIfRelevant:yaps fromViewController:self];
                            }
                         //}
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

- (void) getSelfAndUpdateScore
{
    __weak FriendsViewController *weakSelf = self;

    [[API sharedAPI] getMeWithCallback:^(YSUser *user, NSError *error) {
        if (user) {
            // TODO maybe do a check if the number changed?
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

#pragma mark - Double Tap
- (void) setupDoubleTap
{
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:doubleTap];
}

- (void) handleDoubleTap:(UIGestureRecognizer *)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        CGPoint p = [tap locationInView:tap.view];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath.section > 0) {
            [self cellTappedTwiceAtIndexPath:indexPath];
        }
    }
}

- (void) cellTappedTwiceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Double tap on: %@", indexPath);
    
    if (indexPath.section == 0) {
        // This is our own cell
        return;
    }
    
    YSUser *friend = self.friends[indexPath.row];
    self.selectedFriend = friend;
    
    UIActionSheet *actionSheetSpotify = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Send %@ a song yap or a voice yap?", friend.firstName]
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:@"Send a Song Yap", @"Send a Voice Yap", nil];

    [actionSheetSpotify showInView:self.view];

    /*
    YSContact *contact;
    PhoneContact *phoneContact = [[ContactManager sharedContactManager] contactForPhoneNumber:friend.phone];
    if (phoneContact) {
        contact = phoneContact;
    } else {
        contact = [YSContact contactWithName:friend.displayNameNotFromContacts andPhoneNumber:friend.phone];
    }

    [self performSegueWithIdentifier:@"Send Yap Segue" sender:contact];
     */
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Double Tapped Row"];
}

#pragma mark - UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }

    return self.friends.count;
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSUser *user = indexPath.section == 0 ? [YSUser currentUser] : self.friends[indexPath.row];

    UserCell *cell;
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_EXPANDED forIndexPath:indexPath];
        [cell clearLabels];
        YSUser *myFriend = self.myTopFriends.count > 0 ? self.myTopFriends[0] : nil;
        cell.friendOneImage.hidden = myFriend == nil;
        cell.friendOneLabel.text = myFriend.displayName;
        if (indexPath.section == 0 && self.myTopFriends.count == 0) {
            cell.friendOneLabel.text = self.friendOneLabelString;
        }
        [cell.friendOneLabel sizeToFit];

        myFriend = self.myTopFriends.count > 1 ? self.myTopFriends[1] : nil;
        cell.friendTwoImage.hidden = myFriend == nil;
        cell.friendTwoLabel.text = myFriend.displayName;
        [cell.friendTwoLabel sizeToFit];

        myFriend = self.myTopFriends.count > 2 ? self.myTopFriends[2] : nil;
        cell.friendThreeImage.hidden = myFriend == nil;
        cell.friendThreeLabel.text = myFriend.displayName;
        [cell.friendThreeLabel sizeToFit];
        
        cell.doubleTapLabel.hidden = YES;
    } else if ([indexPath isEqual:self.selectedIndexPath]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_EXPANDED forIndexPath:indexPath];
        [cell clearLabels];
        self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [cell addSubview:self.loadingSpinner];
        self.loadingSpinner.center = CGPointMake(160, 50);
        cell.doubleTapLabel.hidden = NO;

        // Labels will be set in showTopFriendsForIndexPath
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_COLLAPSED forIndexPath:indexPath];
    }
    
    cell.nameLabel.text = indexPath.section == 0 ? user.displayNameNotFromContacts : user.displayName;
    [cell.nameLabel sizeToFit];
    
    cell.scoreLabel.text = [NSString stringWithFormat:@"%d", user.score.intValue];
    [cell.scoreLabel sizeToFit];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return HEIGHT_EXPANDED;
    }
    
    return [indexPath isEqual:self.selectedIndexPath] ? HEIGHT_EXPANDED : HEIGHT_COLLAPSED;
}

- (void) showTopFriendsForIndexPath:(NSIndexPath *)indexPath andFriends:(NSArray *)friends
{
    UserCell *cell = (UserCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if (friends.count == 0) {
        cell.friendOneLabel.text = @"No top friends";
        cell.friendOneImage.hidden = YES;
        [cell.friendOneLabel sizeToFit];
    } else {
        YSUser *userOne = friends[0];
        cell.friendOneLabel.text = userOne.displayName;
        cell.friendOneImage.hidden = NO;
        [cell.friendOneLabel sizeToFit];
    }
    
    YSUser *userTwo = friends.count > 1 ? friends[1] : nil;
    cell.friendTwoImage.hidden = userTwo == nil;
    cell.friendTwoLabel.text = userTwo.displayName;
    [cell.friendTwoLabel sizeToFit];
    
    YSUser *userThree = friends.count > 2 ? friends[2] : nil;
    cell.friendThreeImage.hidden = userThree == nil;
    cell.friendThreeLabel.text = userThree.displayName;
    [cell.friendThreeLabel sizeToFit];
}

- (void) expandAndContractCell:(NSIndexPath *)indexPath
{
    YSUser *expandingUser = self.friends[indexPath.row];
    NSMutableArray *changedIndexPaths = [NSMutableArray array];
    [changedIndexPaths addObject:indexPath];
    
    [self.tableView beginUpdates];
    if (!self.selectedIndexPath) {
        // Nothing is selected yet. Just expand the cell.
        self.selectedIndexPath = indexPath;
    } else if ([indexPath isEqual:self.selectedIndexPath]) {
        // We clicked on the currently selected cell. Just collapse it.
        self.selectedIndexPath = nil;
        expandingUser = nil; // Don't reload the selected user since its collapsing.
    } else {
        // We're expanding this friend and closing another.
        [changedIndexPaths addObject:self.selectedIndexPath];
        self.selectedIndexPath = indexPath;
    }
    
    [self.tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
    
    if (expandingUser) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Friend"];
        NSArray *topFriends = self.topFriendMap[expandingUser.userID];
        if (topFriends && [topFriends isKindOfClass:[NSArray class]]) {
            [self showTopFriendsForIndexPath:indexPath andFriends:topFriends];
        } else {
            [self.loadingSpinner startAnimating];
            FriendsViewController *weakSelf = self;
            [[API sharedAPI] topFriendsForUser:expandingUser withCallback:^(NSArray *friends, NSError *error) {
                [self.loadingSpinner stopAnimating];
                if (error) {
                    
                } else {
                    weakSelf.topFriendMap[expandingUser.userID] = friends;
                    [weakSelf showTopFriendsForIndexPath:indexPath andFriends:friends];
                }
            }];
        }
    }

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Self"];
        return;
    } else {
        __weak FriendsViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf expandAndContractCell:indexPath];
        });
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return section == 0 ? @"You" : [NSString stringWithFormat:@"Friends (%lu)", (unsigned long)self.friends.count];
     
    return @"Double Tap a Friend to Reply";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}
 
- (NSMutableDictionary *) topFriendMap
{
    if (!_topFriendMap) {
        _topFriendMap = [NSMutableDictionary new];
    }
    return _topFriendMap;
}

- (IBAction)addFriendButtonPressed:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Add Friends Button (Plus)"];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        UINavigationController *vc = segue.destinationViewController;
        ContactsViewController *contactsVC = vc.viewControllers.firstObject;
        contactsVC.builder = [AddFriendsBuilder new];
    } else if ([@"Send Yap Segue" isEqualToString:segue.identifier]) {
        AudioCaptureViewController *vc = segue.destinationViewController;
        YSContact *contact = sender;
        vc.contactReplyingTo = contact;
        self.replyWithVoice = NO;
    }
}

- (void) cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapLargeAddFriendsButton
{
    [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Add Friends Button (Large)"];
}

#pragma mark - SMS

- (void)showSMS:(NSString *)message toRecipients:(NSArray *)recipients {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipients];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void) showFriendsSuccessAlert
{
    NSLog(@"Show Friends Success Alert");
    
    double delay = 0.3;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //This is a hack to prevent multiple popups from showing
        //self.smsAlertWasAlreadyPrompted = NO;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend Request Sent"
                                                        message:@"They'll be added to your friends once they accept!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
        case MessageComposeResultCancelled:
            [self recordCanceledYap];
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            [self showSMSSentSuccessfullyPopup];
            break;
            
        default:
            break;
    }
    //This is a hack to prevent multiple popups from showing
    //self.smsAlertWasAlreadyPrompted = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSMSSentSuccessfullyPopup {
    double delay = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message Sent"
                                                        message:@"They'll get your friend request as soon as they download the app!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    });
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Sent SMS (Friend Request)"];
}

#pragma mark - UIActionSheet method implementation

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Tapped Action Sheet; Button Index: %ld", (long)buttonIndex);
    YSContact *contact;
    PhoneContact *phoneContact = [[ContactManager sharedContactManager] contactForPhoneNumber:self.selectedFriend.phone];
    if (phoneContact) {
        contact = phoneContact;
    } else {
        contact = [YSContact contactWithName:self.selectedFriend.displayNameNotFromContacts andPhoneNumber:self.selectedFriend.phone];
    }
    
    if (buttonIndex == 0) {
        [self performSegueWithIdentifier:@"Send Yap Segue" sender:contact];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Yap from Friends (Song)"];
    } else if (buttonIndex == 1) {
        self.replyWithVoice = YES;
        [self performSegueWithIdentifier:@"Send Yap Segue" sender:contact];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Yap from Friends (Voice)"];
    } else {
        NSLog(@"Did tap cancel");
    }
    self.selectedFriend = nil;
}

-(void)recordCanceledYap {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Canceled SMS (Yap)"];
}

@end
