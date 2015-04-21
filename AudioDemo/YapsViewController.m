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
#import "UIViewController+Navigation.h"
#import "YapsCache.h"

#define PENDING_YAPS_SECTION 0

@interface YapsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) PlaybackVC *playbackVC;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) YSYap *yapToBlock; //Saved when the AlertView is shown
@property (strong, nonatomic) IBOutlet UIView *pushEnabledView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@property (strong, nonatomic) UIImage *blueArrowFull;
@property (strong, nonatomic) UIImage *blueArrowEmpty;
@property (strong, nonatomic) UIImage *redSquareFull;
@property (strong, nonatomic) UIImage *redSquareEmptyOpenedOnce;
@property (strong, nonatomic) UIImage *redSquareEmptyOpenedTwice;

@property (nonatomic, readonly) NSArray *yaps;

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
    
    if (self.comingFromContactsOrAddTextPage) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MicrophoneWhite30.png"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(didTapGoToAudioCaptureButton)];
        [self showFirstYapAlert];
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    if (!self.comingFromContactsOrAddTextPage) {
        [self loadYaps];
    }
    
    // Pull down to refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self setupNotifications];

    [self setupTableViewGestureRecognizers];
    
    if (![YSPushManager sharedPushManager].pushEnabled) {
        self.pushEnabledView.hidden = NO;
       
        if (!self.didViewNotificationAlert) {
            if (self.unopenedYapsCount.intValue > 0 && ([AppDelegate sharedDelegate].appOpenedCount > 2)) {
                double delay = 0.5;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn on Notifications"
                                                                    message:@"To avoid missing out on yaps from friends, turn on notifications for YapTap in your phone's settings."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles: nil];
                    [alert show];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_PUSH_NOTIFICATION_POPUP];
                });
            }
        }
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

- (NSArray *)yaps
{
    return [YapsCache sharedCache].yaps;
}

- (void) loadYaps {
    __weak YapsViewController *weakSelf = self;
    NSLog(@"YAPS: about to make yaps call");
    [[YapsCache sharedCache] loadYapsWithCallback:^(NSArray *yaps, NSError *error) {
        if (yaps) {
            [weakSelf.refreshControl endRefreshing];
            [weakSelf.tableView reloadData];
            if (yaps.count == 0) {
                self.navigationItem.title = @"Your Yaps (0)";
            } else {
                self.navigationItem.title = @"Your Yaps";
            }
        } else {
            NSLog(@"Error! %@", error);
            double delay = 0.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Loading Yaps!"];
            });
        }
    }];
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
                                [YapsCache sharedCache].yaps = yaps;
                                [weakSelf.tableView reloadData];
                                break;
                            }
                        }
                    }];

    [center addObserverForName:NEW_YAP_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [weakSelf loadYaps];
    }];
    
    [center addObserverForName:NOTIFICATION_YAP_SENT
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        weakSelf.pendingYaps = nil;
                        [weakSelf loadYaps];
                    }];
    
    [center addObserverForName:NOTIFICATION_YAP_SENDING_FAILED
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        double delay = 0.1;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Yap Didn't Send!"];
                        });
                        weakSelf.pendingYaps = nil;
                        [weakSelf.tableView reloadData];
                    }];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) showFirstYapAlert {
    if (self.pendingYaps.count > 0) {
        YSYap* yap = self.pendingYaps[0];
        double delay = 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (!self.didViewFirstYapAlert) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congrats"
                                                                message:[NSString stringWithFormat:@"You sent your first yap! %@ will be added to your friends list after opening your yap!", yap.displayReceiverName]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_FIRST_YAP_ALERT];
            }
        });
    }
}

#pragma UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == PENDING_YAPS_SECTION ? self.pendingYaps.count : self.yaps.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap* yap = indexPath.section == PENDING_YAPS_SECTION ? self.pendingYaps[indexPath.row] : self.yaps[indexPath.row];
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.createdTimeLabel.font = [UIFont systemFontOfSize:11];
    
    
    // SPOTIFY
    if (([yap.type isEqual:MESSAGE_TYPE_SPOTIFY] && yap.receivedByCurrentUser && yap.wasOpened) || ([yap.type isEqual:MESSAGE_TYPE_SPOTIFY] && yap.sentByCurrentUser))
    {
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
    if (yap.receivedByCurrentUser) {
        cell.nameLabel.text = yap.displaySenderName;
        cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@" , [self.dateFormatter stringFromDate:yap.createdAt]];
        
        if (yap.wasOpened) {
            if (yap.wasOpenedOnce) {
                cell.icon.image = self.redSquareEmptyOpenedOnce;
            } else if (yap.wasOpenedTwice) {
                cell.icon.image = self.redSquareEmptyOpenedTwice;
            }
        } else {
            cell.icon.image = self.redSquareFull;
        }
    
    // DID RECEIVE YAP
    } else if (yap.sentByCurrentUser) {
        cell.nameLabel.text = yap.displayReceiverName;
        
        if (yap.wasOpened) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Opened" , [self.dateFormatter stringFromDate:yap.createdAt]];
            cell.icon.image = self.blueArrowEmpty;
        } else if (!yap.wasOpened) {
            cell.icon.image = self.blueArrowFull;
            if (yap.isPending) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Pending" , [self.dateFormatter stringFromDate:yap.createdAt]];
            } else if (yap.isSending) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Sending" , [self.dateFormatter stringFromDate:yap.createdAt]];
            } else {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Delivered" , [self.dateFormatter stringFromDate:yap.createdAt]];
            }
        }
    }
    
    if (yap.isSending) {
        //cell.icon.hidden = YES;
        //[cell.spinner startAnimating];
    } else {
        cell.icon.hidden = NO;
        //[cell.spinner stopAnimating];
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return;
    }

    YSYap *yap = self.yaps[indexPath.row];
    if (yap.receivedByCurrentUser) {
        if (yap.wasOpened) {
            YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
                cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:10];
            } else {
                cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:11];
            }
            
            if (yap.wasOpened) {
                if (yap.wasOpenedOnce) {
                    cell.createdTimeLabel.text = @"Double Tap to Reply. Hold to Replay.";
                } else if (yap.wasOpenedTwice) {
                    cell.createdTimeLabel.text = @"Double Tap to Reply.";
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSIndexPath* adjustedPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
                [self.tableView reloadRowsAtIndexPaths:@[adjustedPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        } else if (!yap.wasOpened) {
            if ([self internetIsNotReachable]){
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
                });
            } else {
                [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
            }
        }
        
    } else if (yap.sentByCurrentUser) {
        YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:11];
        
        if (yap.wasOpened) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@ opened your yap", yap.displayReceiverName];
        } else if (!yap.wasOpened) {
            if (yap.isPending) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"Will be delivered once %@ joins",  yap.displayReceiverName];
            } else if (yap.isSending) {
                NSLog(@"Tapped cell with status of isSending");
            } else {
                cell.createdTimeLabel.text = @"Your yap has been delivered";
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSIndexPath* adjustedPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
            [self.tableView reloadRowsAtIndexPaths:@[adjustedPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
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

- (void) cellLongPressedAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Long Pressed on: %@", indexPath);
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Long Pressed Row"];
    
    YSYap *yap = self.yaps[indexPath.row];
    
    if ([yap.status isEqual: @"opened2"]) {
        [self alreadyReplayedYapAlert];
    } else {
        [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
    }
}

- (void) alreadyReplayedYapAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Replayed Yap"
                                                    message:@"You can only replay a yap one time."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Playback Segue" isEqualToString:segue.identifier]) {
        PlaybackVC *vc = segue.destinationViewController;
        YSYap *yap = sender;
        vc.yap = yap;
    } else if ([@"Reply Segue" isEqualToString:segue.identifier]) {
        AudioCaptureViewController *audioVC = segue.destinationViewController;
        YSYap *yap = sender;

        NSString *targetPhone; // The phone number we're replying to
        NSString *targetName; // The name we're replying to
        if (yap.sentByCurrentUser) {
            targetPhone = yap.receiverPhone;
            targetName = yap.receiverName;
        } else {
            targetPhone = yap.senderPhone;
            targetName = yap.senderName;
        }
        
        PhoneContact *contact = [[ContactManager sharedContactManager] contactForPhoneNumber:targetPhone];
        if (contact) {
            audioVC.contactReplyingTo = contact;
        } else {
            YSContact *contact = [YSContact contactWithName:targetName andPhoneNumber:targetPhone];
            audioVC.contactReplyingTo = contact;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.yaps.count <= indexPath.row) { return NO; }
    
    YSYap *yap = self.yaps[indexPath.row];
    
    if (yap.receivedByCurrentUser) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.yaps.count <= indexPath.row) { return; }

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
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.0f;
    [self.tableView addGestureRecognizer:longPress];
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

- (void) handleLongPress:(UIGestureRecognizer *)tap
{
    if (UIGestureRecognizerStateBegan == tap.state)
    {
        CGPoint p = [tap locationInView:tap.view];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath.section > 0) {
            [self cellLongPressedAtIndexPath:indexPath];
        }
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

- (void)didTapGoToAudioCaptureButton {
    [self popToBaseAudioCaptureController:YES];
}

- (void) removeBlockedYap
{
    NSMutableArray *mutableYaps = [NSMutableArray arrayWithArray:self.yaps];
    [self.tableView beginUpdates];
    NSUInteger index = [mutableYaps indexOfObject:self.yapToBlock];
    [mutableYaps removeObjectAtIndex:index];
    [YapsCache sharedCache].yaps = mutableYaps;

    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]]
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
                                double delay = 0.5;
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Blocking User!"];
                                });
                            }
                        }];
    }
}

- (IBAction)didTapSettingsButton
{
    self.settingsButton.enabled = NO;
    [self performSegueWithIdentifier:@"Settings Segue" sender:nil];
}

#pragma mark - Image Getters
- (UIImage *) blueArrowEmpty
{
    if (!_blueArrowEmpty) {
        _blueArrowEmpty = [UIImage imageNamed:@"YapIconOpenedSent3.png"];
    }
    return _blueArrowEmpty;
}

- (UIImage *) blueArrowFull
{
    if (!_blueArrowFull) {
        _blueArrowFull = [UIImage imageNamed:@"YapIconUnopenedSent.png"];
    }
    return _blueArrowFull;
}

- (UIImage *) redSquareEmptyOpenedOnce
{
    if (!_redSquareEmptyOpenedOnce) {
        _redSquareEmptyOpenedOnce = [UIImage imageNamed:@"OpenGift700.png"];
    }
    return _redSquareEmptyOpenedOnce;
}

- (UIImage *) redSquareEmptyOpenedTwice
{
    if (!_redSquareEmptyOpenedTwice) {
        _redSquareEmptyOpenedTwice = [UIImage imageNamed:@"YapsIconReceivedOpened.png"];
    }
    return _redSquareEmptyOpenedTwice;
}

- (UIImage *) redSquareFull
{
    if (!_redSquareFull) {
        _redSquareFull = [UIImage imageNamed:@"YapsIconReceivedUnopened2.png"];
    }
    return _redSquareFull;
}

- (BOOL) didViewNotificationAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_PUSH_NOTIFICATION_POPUP];
}

- (BOOL) didViewFirstYapAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_FIRST_YAP_ALERT];
}

@end
