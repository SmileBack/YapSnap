//
//  YapsViewController.m
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YapsViewController.h"
#import "API.h"
#import "YapCell.h"
#import "PlaybackVC.h"
#import "AudioCaptureViewController.h"
#import "AppDelegate.h"
#import "YSMicSourceController.h"
#import "YSSpotifyTapGestureRecognizer.h"
#import "OpenInSpotifyAlertView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>
#import "ContactManager.h"
#import "YSPushManager.h"

@interface YapsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *yaps;
@property (nonatomic, strong) PlaybackVC *playbackVC;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) YSYap *yapToBlock; //Saved when the AlertView is shown
@property (strong, nonatomic) IBOutlet UIView *pushEnabledView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@property (strong, nonatomic) UIImage *blueArrowFull;
@property (strong, nonatomic) UIImage *blueArrowEmpty;
@property (strong, nonatomic) UIImage *redSquareFull;
@property (strong, nonatomic) UIImage *redSquareEmpty;

- (IBAction)didTapSettingsButton;

@end

static NSString *CellIdentifier = @"Cell";

@implementation YapsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Yaps Page"];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    self.dateFormatter.doesRelativeDateFormatting = YES;
    self.dateFormatter.locale = [NSLocale currentLocale];
    
    self.navigationItem.title = @"Your Yaps";
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self loadYaps];

    // Pull down to refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self setupNotifications];

    [self setupTableViewGestureRecognizers];
    
    if (![YSPushManager sharedPushManager].pushEnabled) {
        self.pushEnabledView.hidden = NO;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    self.settingsButton.enabled = YES;
}

- (void) refresh:(UIRefreshControl *)refreshControl {
    [self loadYaps];
}

- (void) loadYaps {
    __weak YapsViewController *weakSelf = self;
    [[API sharedAPI] getYapsWithCallback:^(NSArray *yaps, NSError *error) {
        if (yaps) {
            [weakSelf.refreshControl endRefreshing];
            weakSelf.yaps = yaps;
            [weakSelf.tableView reloadData];
        } else {
            NSLog(@"Error! %@", error);
            [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Loading Yaps!"];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"API Error - getYaps"];
        }
    }];
}

- (IBAction)didPressFriendsButton:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"Friends Segue" sender:nil];
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    __weak YapsViewController *weakSelf = self;

    [center addObserverForName:UIApplicationDidEnterBackgroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"popToBaseAudioCaptureController");
                        [self popToBaseAudioCaptureController:NO];
                    }];
    
    [center addObserverForName:NOTIFICATION_YAP_OPENED
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        YSYap *newYap = note.object;
                        for (int i = 0; i < weakSelf.yaps.count; i++) {
                            YSYap *yap = weakSelf.yaps[i];
                            if ([yap.yapID isEqualToNumber:newYap.yapID]) {
                                NSMutableArray *yaps = [NSMutableArray arrayWithArray:weakSelf.yaps];
                                [yaps replaceObjectAtIndex:i withObject:newYap];
                                weakSelf.yaps = yaps;
                                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                break;
                            }
                        }
                    }];

    [center addObserverForName:NEW_YAP_NOTIICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [weakSelf loadYaps];
    }];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

#pragma UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.yaps.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap* yap = self.yaps[indexPath.row];
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.createdTimeLabel.font = [UIFont systemFontOfSize:11];
    
    
    // SPOTIFY
    if ([yap.type isEqual:MESSAGE_TYPE_SPOTIFY] && yap.receivedByCurrentUser && yap.wasOpened) {
        cell.goToSpotifyView.alpha = 1;
        //Add gesture recognizer
        YSSpotifyTapGestureRecognizer *singleFingerTap =
        [[YSSpotifyTapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(handleSpotifyTap:)];
        singleFingerTap.yap = yap;
        [cell.goToSpotifyView addGestureRecognizer:singleFingerTap];
        
        [cell.albumImageView sd_setImageWithURL:[NSURL URLWithString:yap.imageURL]];
        [cell.albumImageView.layer setBorderColor: [[UIColor darkGrayColor] CGColor]];
        [cell.albumImageView.layer setBorderWidth: 0.5];
    } else {
        cell.goToSpotifyView.alpha = 0;
    }

    
    // DID SEND YAP
    if (yap.sentByCurrentUser) {
        cell.nameLabel.text = yap.displayReceiverName;
        
        if (yap.wasOpened) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Opened" , [self.dateFormatter stringFromDate:yap.createdAt]];
            cell.icon.image = self.blueArrowEmpty;
        } else if (!yap.wasOpened) {
            cell.icon.image = self.blueArrowFull;
            if (yap.isPending) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Pending" , [self.dateFormatter stringFromDate:yap.createdAt]];
            } else {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Delivered" , [self.dateFormatter stringFromDate:yap.createdAt]];
            }
        }
        
    // DID RECEIVE YAP
    } else if (yap.receivedByCurrentUser) {
        cell.nameLabel.text = yap.displaySenderName;
        cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@" , [self.dateFormatter stringFromDate:yap.createdAt]];

        if (yap.wasOpened) {
            cell.icon.image = self.redSquareEmpty;
        } else {
            cell.icon.image = self.redSquareFull;
        }
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self internetIsNotReachable]){ // Only apply reachability code to situation where user can listen to the yap
        [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
    } else {        
        YSYap *yap = self.yaps[indexPath.row];
        if (yap.receivedByCurrentUser) {
            if (yap.wasOpened) {
                YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:11];

                cell.createdTimeLabel.text = @"Double Tap to Reply";

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            } else if (!yap.wasOpened) {
                [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
            }
            
        } else if (yap.sentByCurrentUser) {
            YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:11];
            
            if (yap.wasOpened) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@ opened your yap", yap.displayReceiverName];
            } else if (!yap.wasOpened) {
                if (yap.isPending) {
                    cell.createdTimeLabel.text = [NSString stringWithFormat:@"Yap will be delivered once %@ joins",  yap.displayReceiverName];
                } else {
                    cell.createdTimeLabel.text = @"Your yap has been delivered";
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
    }
}

- (void) cellTappedTwiceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Double tap on: %@", indexPath);
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Double Tapped Row"];
    
    YSYap *yap = self.yaps[indexPath.row];
    [self performSegueWithIdentifier:@"Reply Segue" sender:yap];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Playback Segue" isEqualToString:segue.identifier]) {
        PlaybackVC *vc = segue.destinationViewController;
        YSYap *yap = sender;
        vc.yap = yap;
    } else if ([@"Reply Segue" isEqualToString:segue.identifier]) {
        AudioCaptureViewController *audioVC = segue.destinationViewController;
        YSYap *yap = sender;
        PhoneContact *contact = [[ContactManager sharedContactManager] contactForPhoneNumber:yap.senderPhone];
        if (contact) {
            audioVC.contactReplyingTo = contact;
        } else {
            YSContact *contact = [YSContact contactWithName:yap.senderName andPhoneNumber:yap.senderPhone];
            audioVC.contactReplyingTo = contact;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap *yap = self.yaps[indexPath.row];
    
    if (yap.receivedByCurrentUser) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap *yap = self.yaps[indexPath.row];
        
    if (yap.receivedByCurrentUser) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Block User"
                                                            message:[NSString stringWithFormat:@"You will no longer receive messages from %@. This cannot be undone.", yap.displaySenderName]
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel" otherButtonTitles:@"Block", nil];
        self.yapToBlock = yap;

        [alertView show];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Block";
}

# pragma mark - Gesture Recognition
- (void) setupTableViewGestureRecognizers
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
        [self cellTappedTwiceAtIndexPath:indexPath];
    }
}


//The event handling method
- (void)handleSpotifyTap:(YSSpotifyTapGestureRecognizer *)recognizer {
    //CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    YSYap *yap = recognizer.yap;
    NSLog(@"Tapped go to spotify view for yap: %@", yap.playbackURL);
    OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithYap:yap];
    [alert show];
}

- (void) popToBaseAudioCaptureController:(BOOL)animated
{
    NSArray *vcs = self.navigationController.viewControllers;
    for (UIViewController *vc in vcs) {
        if ([vc isKindOfClass:[AudioCaptureViewController class]]) {
            if (!animated) {
                [self.navigationController popToViewController:vc animated:NO];
                AudioCaptureViewController *audioVC = (AudioCaptureViewController *)vc;
                [audioVC resetUI];
            } else {
                BOOL animate = [vcs indexOfObject:self] - 1 == [vcs indexOfObject:vc];
                if (!animate) {
                    AudioCaptureViewController *audioVC = (AudioCaptureViewController *)vc;
                    [audioVC resetUI];
                }
                [self.navigationController popToViewController:vc animated:animate];
                break;
            }
        }
    }
}

- (void)didTapGoToAudioCaptureButton {
    [self popToBaseAudioCaptureController:YES];
}

- (void) removeBlockedYap
{
    NSMutableArray *mutableYaps = [NSMutableArray arrayWithArray:self.yaps];
    [self.tableView beginUpdates];
    NSUInteger index = [mutableYaps indexOfObject:self.yapToBlock];
    [mutableYaps removeObjectAtIndex:index];
    self.yaps = mutableYaps;
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // If user confirms blocking do this:
        NSLog(@"User confirms blocking");
        
        __weak YapsViewController *weakSelf = self;
        
        [[API sharedAPI] blockUserId:self.yapToBlock.senderID
                        withCallback:^(BOOL success, NSError *error) {
                            if (success) {
                                NSLog(@"Blocking Worked");
                                [weakSelf removeBlockedYap];
                            } else {
                                NSLog(@"Error blocking! %@", error);
                                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Blocking User!"];
                                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                [mixpanel track:@"API Error - blockUser"];
                            }
                        }];
    }
}

#pragma mark - Image Getters
- (UIImage *) blueArrowEmpty
{
    if (!_blueArrowEmpty) {
        _blueArrowEmpty = [UIImage imageNamed:@"BlueArrowWhiteFilling.png"];
    }
    return _blueArrowEmpty;
}

- (UIImage *) blueArrowFull
{
    if (!_blueArrowFull) {
        _blueArrowFull = [UIImage imageNamed:@"BlueArrow2.png"];
    }
    return _blueArrowFull;
}

- (UIImage *) redSquareEmpty
{
    if (!_redSquareEmpty) {
        _redSquareEmpty = [UIImage imageNamed:@"RedRoundedSquareWhiteFilling.png"];
    }
    return _redSquareEmpty;
}

- (UIImage *) redSquareFull
{
    if (!_redSquareFull) {
        _redSquareFull = [UIImage imageNamed:@"RedRoundedSquare.png"];
    }
    return _redSquareFull;
}

- (IBAction)didTapSettingsButton
{
    self.settingsButton.enabled = NO;
    [self performSegueWithIdentifier:@"Settings Segue" sender:nil];
}

@end
