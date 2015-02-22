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

@interface YapsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *yaps;
@property (nonatomic, strong) PlaybackVC *playbackVC;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@property (nonatomic, strong) YSYap *yapToBlock; //Saved when the AlertView is shown
@end

static NSString *CellIdentifier = @"Cell";

@implementation YapsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
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

    NSString *cellType = yap.sentByCurrentUser ? @"Sent Cell" : @"Received Cell";
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    cell.createdTimeLabel.font = [UIFont systemFontOfSize:11];
    
    // DID SEND YAP
    if (yap.sentByCurrentUser) {
        cell.nameLabel.text = yap.displayReceiverName;
        UIImageView *cellIcon = [[UIImageView alloc] init];
        cellIcon.frame = CGRectMake(12, 31, 24, 27);
        [cell addSubview:cellIcon];
        
        // UNOPENED
        if (!yap.wasOpened) {
            cellIcon.image = [UIImage imageNamed:@"BlueArrow2.png"];
            if (yap.isPending) {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Pending" , [self.dateFormatter stringFromDate:yap.createdAt]];
            } else {
                cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Delivered" , [self.dateFormatter stringFromDate:yap.createdAt]];
            }
        
        // OPENED
        } else if (yap.wasOpened) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@  |  Opened" , [self.dateFormatter stringFromDate:yap.createdAt]];
            cellIcon.image = [UIImage imageNamed:@"BlueArrowWhiteFilling.png"];
        }
        
    // DID RECEIVE YAP
    } else if (yap.receivedByCurrentUser) {
        cell.nameLabel.text = yap.displaySenderName;
        cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@" , [self.dateFormatter stringFromDate:yap.createdAt]];
        
        UIImageView *cellIcon = [[UIImageView alloc] init];
        cellIcon.frame = CGRectMake(11, 29, 24, 24);
        [cell addSubview:cellIcon];
        
        // UNOPENED
        if ([yap.status isEqual: @"unopened"]) {
            cellIcon.image = [UIImage imageNamed:@"RedRoundedSquare.png"];
            
        // OPENED
        } else if ([yap.status  isEqual: @"opened"]) {
            cellIcon.image = [UIImage imageNamed:@"RedRoundedSquareWhiteFilling.png"];
            
            // SPOTIFY
            if ([yap.type isEqual:MESSAGE_TYPE_SPOTIFY]) {
                cell.goToSpotifyView = [[UIView alloc] initWithFrame:CGRectMake(238, 8, 74, 74)];
                [cell addSubview:cell.goToSpotifyView];
                
                //Add gesture recognizer
                YSSpotifyTapGestureRecognizer *singleFingerTap =
                [[YSSpotifyTapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(handleSpotifyTap:)];
                singleFingerTap.yap = yap;
                [cell.goToSpotifyView addGestureRecognizer:singleFingerTap];
                
                UIImageView *albumImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 74, 74)];
                [albumImage sd_setImageWithURL:[NSURL URLWithString:yap.imageURL]];
                [albumImage.layer setBorderColor: [[UIColor darkGrayColor] CGColor]];
                [albumImage.layer setBorderWidth: 0.5];
                [cell.goToSpotifyView addSubview:albumImage];
                
                UIImageView *listenOnSpotifyImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listen_on_spotify-black2.png"]];
                listenOnSpotifyImage.frame = CGRectMake(0, 52, 74, 22);
                [cell.goToSpotifyView addSubview:listenOnSpotifyImage];
            } else {
                
            }
        }
    }
    
    return cell;
}

- (void) cellTappedOnceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRow");
    
    if ([self internetIsNotReachable]){ // Only apply reachability code to situation where user can listen to the yap
        [self showNoInternetAlert];
    } else {        
        YSYap *yap = self.yaps[indexPath.row];
        if (yap.receivedByCurrentUser) {
            /*if (yap.wasOpened) {
                YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.createdTimeLabel.font = [UIFont italicSystemFontOfSize:11];

                cell.createdTimeLabel.text = @"Double Tap to Reply";

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            } else if (!yap.wasOpened) { */
                [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
          //  }
            
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
    
    YSYap *yap = self.yaps[indexPath.row];
    if (yap.receivedByCurrentUser) {
        [self performSegueWithIdentifier:@"Reply Segue" sender:yap];
    }
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
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.tableView addGestureRecognizer:singleTap];
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

- (void) handleSingleTap:(UIGestureRecognizer *)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        CGPoint p = [tap locationInView:tap.view];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        [self cellTappedOnceAtIndexPath:indexPath];
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
                            }
                        }];
    }
}

@end
