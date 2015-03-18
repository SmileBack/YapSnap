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

#define CELL_COLLAPSED @"Collapsed Cell"
#define CELL_EXPANDED @"Expanded Cell"

#define HEIGHT_COLLAPSED 50.0f
#define HEIGHT_EXPANDED 100.0f


@interface FriendsViewController()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *myTopFriends;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSMutableDictionary *topFriendMap; //Friend ID :: Top friends array
@property (strong, nonatomic) IBOutlet UIView *friendsExplanationView;

- (IBAction)tappedCancelFeedbackExplanationButton;

@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Friends Page"];

    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:0.99]];
    
    self.navigationItem.title = @"Friends";

    __weak FriendsViewController *weakSelf = self;
    [[API sharedAPI] friends:^(NSArray *friends, NSError *error) {
        if (error) {
            double delay = 0.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Loading Friends!"];
                
            });
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"API Error - friends"];
        } else {
            if (friends.count > 2) {
                self.myTopFriends = [friends subarrayWithRange:NSMakeRange(0, 3)];
            } else if (friends.count > 0) {
                self.myTopFriends = friends;
            }

            weakSelf.friends = [friends sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                YSUser *user1 = obj1;
                YSUser *user2 = obj2;
                return [user1.displayName compare:user2.displayName];
            }];
            [weakSelf.tableView reloadData];
        }
    }];
    
    if (!self.didTapCancelFeedbackExplanationButton) {
        self.friendsExplanationView.hidden = NO;
    }
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    [UIView animateWithDuration:1
                          delay:.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.friendsExplanationView.frame = CGRectMake(0, 0, 320, 118);
                     }
                     completion:nil];
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
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
        [cell.friendOneLabel sizeToFit];

        myFriend = self.myTopFriends.count > 1 ? self.myTopFriends[1] : nil;
        cell.friendTwoImage.hidden = myFriend == nil;
        cell.friendTwoLabel.text = myFriend.displayName;
        [cell.friendTwoLabel sizeToFit];

        myFriend = self.myTopFriends.count > 2 ? self.myTopFriends[2] : nil;
        cell.friendThreeImage.hidden = myFriend == nil;
        cell.friendThreeLabel.text = myFriend.displayName;
        [cell.friendThreeLabel sizeToFit];
    } else if ([indexPath isEqual:self.selectedIndexPath]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_EXPANDED forIndexPath:indexPath];
        [cell clearLabels];
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Self"];
        return;
    }
    YSUser *expandingUser = self.friends[indexPath.row];
    NSMutableArray *changedIndexPaths = [NSMutableArray array];
    [changedIndexPaths addObject:indexPath];

    [tableView beginUpdates];
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

    [tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [tableView endUpdates];

    if (expandingUser) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Friend"];
        NSArray *topFriends = self.topFriendMap[expandingUser.userID];
        if (topFriends && [topFriends isKindOfClass:[NSArray class]]) {
            [self showTopFriendsForIndexPath:indexPath andFriends:topFriends];
        } else {
            FriendsViewController *weakSelf = self;
            [[API sharedAPI] topFriendsForUser:expandingUser withCallback:^(NSArray *friends, NSError *error) {
                if (error) {
                    [[YTNotifications sharedNotifications] showNotificationText:@"Error Loading Top Friends!"];
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"API Error - topFriends"];
                } else {
                    weakSelf.topFriendMap[expandingUser.userID] = friends;
                    [weakSelf showTopFriendsForIndexPath:indexPath andFriends:friends];
                }
            }];
        }
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"You" : [NSString stringWithFormat:@"Friends (%lu)", (unsigned long)self.friends.count];
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

- (void) tappedCancelFeedbackExplanationButton
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_CANCEL_BUTTON_ON_FRIENDS_EXPLANATION_VIEW_KEY];
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.friendsExplanationView.frame = CGRectMake(0, screenHeight, 320, 118);
                     }
                     completion:^(BOOL finished) {
                         self.friendsExplanationView.hidden = YES;
                     }];
}

- (BOOL) didTapCancelFeedbackExplanationButton
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_CANCEL_BUTTON_ON_FRIENDS_EXPLANATION_VIEW_KEY];
    
}

- (IBAction)addFriendButtonPressed:(UIBarButtonItem *)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Add Friend"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add a Friend"
                                                    message:@"To add a friend, send a yap to anyone from your contacts. Once they open it, they'll become your friend!"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Send Yap", nil];
    [alert show];
}

- (IBAction)tappedCancelButton:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Send Yap in UIAlert"];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
