//
//  YapsViewController.m
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "YapsViewController.h"
#import "MBProgressHUD.h"
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
@property (nonatomic, strong) UIView *goToSpotifyView;

- (IBAction)didTapGoToAudioCaptureButton;

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
    
    //self.navigationItem.hidesBackButton = YES;
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self loadYaps];

    // Pull down to refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:APP_ENTERED_BACKGROUND_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        
                        NSArray *viewControllers = [[self navigationController] viewControllers];
                        for( int i=0;i<[viewControllers count];i++){
                            id obj=[viewControllers objectAtIndex:[viewControllers count]-i-1];
                            if([obj isKindOfClass:[AudioCaptureViewController class]]){
                                // Reset AudioCaptureViewController, then pop
                                AudioCaptureViewController* audioCaptureVC = obj;
                                if (![audioCaptureVC isInRecordMode]) {
                                    YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
                                    audioCaptureVC.micModeButton.alpha = 1;
                                    audioCaptureVC.spotifyModeButton.alpha = .2;
                                    [audioCaptureVC flipController:audioCaptureVC.audioSource to:micSource];
                                }
                                
                                [[self navigationController] popToViewController:obj animated:NO];
                                return;
                            }
                        }
                        
                    }];

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

    BOOL didSendYap = [[yap.senderID stringValue] isEqualToString:[Global retrieveValueForKey:@"current_user_id"]];
    NSString *cellType = didSendYap ? @"Sent Cell" : @"Received Cell";
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    // DID SEND YAP
    if (didSendYap) {
        cell.nameLabel.text = yap.displayReceiverName;
        UIImageView *cellIcon = [[UIImageView alloc] init];
        cellIcon.frame = CGRectMake(12, 31, 24, 27);
        [cell addSubview:cellIcon];
        
        // UNOPENED
        if ([yap.status isEqual: @"unopened"]) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"Sent %@  |  Delivered" , [self.dateFormatter stringFromDate:yap.createdAt]];
            cellIcon.image = [UIImage imageNamed:@"BlueArrow2.png"];
        
        // OPENED
        } else if ([yap.status  isEqual: @"opened"]) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"Sent %@  |  Opened" , [self.dateFormatter stringFromDate:yap.createdAt]];
            cellIcon.image = [UIImage imageNamed:@"BlueArrowWhiteFilling.png"];
        }
        
    // DID RECEIVE YAP
    } else {
        cell.nameLabel.text = yap.displaySenderName;
        cell.createdTimeLabel.text = [NSString stringWithFormat:@"Received %@" , [self.dateFormatter stringFromDate:yap.createdAt]];
        
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
                self.goToSpotifyView = [[UIView alloc] initWithFrame:CGRectMake(238, 8, 74, 74)];
                [cell addSubview:self.goToSpotifyView];
                
                //Add gesture recognizer
                YSSpotifyTapGestureRecognizer *singleFingerTap =
                [[YSSpotifyTapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(handleSpotifyTap:)];
                singleFingerTap.yap = yap;
                [self.goToSpotifyView addGestureRecognizer:singleFingerTap];
                
                UIImageView *albumImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 74, 74)];
                [albumImage sd_setImageWithURL:[NSURL URLWithString:yap.imageURL]];
                [albumImage.layer setBorderColor: [[UIColor darkGrayColor] CGColor]];
                [albumImage.layer setBorderWidth: 0.5];
                [self.goToSpotifyView addSubview:albumImage];
                
                UIImageView *listenOnSpotifyImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listen_on_spotify-black2.png"]];
                listenOnSpotifyImage.frame = CGRectMake(0, 52, 74, 22);
                [self.goToSpotifyView addSubview:listenOnSpotifyImage];
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
        if (yap.isOpened) {
            YapCell *cell = (YapCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.createdTimeLabel.text = @"Double Tap to reply bitches";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        } else {
            [self performSegueWithIdentifier:@"Playback Segue" sender:yap]; // Remove this line from here eventually
        }
        
    //    BOOL didSendYap = [[yap.senderID stringValue] isEqualToString:[Global retrieveValueForKey:@"current_user_id"]];

        // DID SEND YAP
    //    if (didSendYap) {
    //        // REPLACE THIS WITH A LESS INTRUSIVE UI
    //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your message has been delivered"
    //                                                        message:@"(Replace this with something less intrusive)."
    //                                                       delegate:nil
    //                                              cancelButtonTitle:@"OK"
    //                                              otherButtonTitles:nil];
    //        [alert show];
    //        
    //    // DID RECEIVE YAP
    //    } else {
    //        
    //        // UNOPENED
    //        if ([yap.status  isEqual: @"unopened"]) {
    //            [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
    //        
    //        // OPENED
    //        } else {
    //            // REPLACE THIS WITH A LESS INTRUSIVE UI
    //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Opened"
    //                                                            message:@"(Replace this with something less intrusive)."
    //                                                           delegate:nil
    //                                                  cancelButtonTitle:@"OK"
    //                                                  otherButtonTitles:nil];
    //            [alert show];
    //        }
    //    }
    }
}

- (void) cellTappedTwiceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Double tap on: %@", indexPath);
    
    YSYap *yap = self.yaps[indexPath.row];

    AudioCaptureViewController *audioVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AudioCaptureViewController"];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:audioVC];
    audioVC.contactReplyingTo = [[ContactManager sharedContactManager] contactForPhoneNumber:yap.senderPhone];
    [self presentViewController:navVC animated:NO completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Playback Segue" isEqualToString:segue.identifier]) {
        PlaybackVC *vc = segue.destinationViewController;
        YSYap *yap = sender;
        vc.yap = yap;
    }
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

- (void)didTapGoToAudioCaptureButton {
    NSLog(@"Tapped Go To Audio Capture Page");
    
    NSArray *viewControllers = [[self navigationController] viewControllers];
    for( int i=0;i<[viewControllers count];i++){
        id obj=[viewControllers objectAtIndex:[viewControllers count]-i-1];
        if([obj isKindOfClass:[AudioCaptureViewController class]]){
            if (self.comingFromAudioCaptureScreen) {
                [[self navigationController] popToViewController:obj animated:YES];
            } else {
                // Reset AudioCaptureViewController, then pop
                AudioCaptureViewController* audioCaptureVC = obj;
                if (![audioCaptureVC isInRecordMode]) {
                    YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
                    audioCaptureVC.micModeButton.alpha = 1;
                    audioCaptureVC.spotifyModeButton.alpha = .2;
                    [audioCaptureVC flipController:audioCaptureVC.audioSource to:micSource];
                }
                
                [[self navigationController] popToViewController:obj animated:NO];
            }
            return;
        }
    }
}

@end
