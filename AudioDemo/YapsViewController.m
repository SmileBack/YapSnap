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
            if ([yap.type  isEqual: @"SpotifyMessage"]) {
                self.goToSpotifyView = [[UIView alloc] init];
                self.goToSpotifyView.frame = CGRectMake(238, 8, 74, 74);
                [cell addSubview:self.goToSpotifyView];
                
                //Add gesture recognizer
                UITapGestureRecognizer *singleFingerTap =
                [[UITapGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(handleSingleTap:)];
                [self.goToSpotifyView addGestureRecognizer:singleFingerTap];
                
                UIImageView *albumImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ColdplayAlbumImage.jpg"]];
                albumImage.frame = CGRectMake(0, 0, 74, 74);
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRow");
    
    if ([self internetIsNotReachable]){
        [self showNoInternetAlert];
    } else {        
        YSYap *yap = self.yaps[indexPath.row];
        [self performSegueWithIdentifier:@"Playback Segue" sender:yap]; // Remove this line from here eventually
        
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

//- (void)doDoubleTap
//{
//    NSLog(@"Double Tapped Row");
//    [Global storeValue:@"3475238941" forKey:@"reply_recipient"];
//    [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self]; // UNDO
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Playback Segue" isEqualToString:segue.identifier]) {
        PlaybackVC *vc = segue.destinationViewController;
        YSYap *yap = sender;
        vc.yap = yap;
    }
}

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    //CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    NSLog(@"Tapped go to spotify view");
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
                [[self navigationController] popToViewController:obj animated:NO];
            }
            return;
        }
    }
}


@end
