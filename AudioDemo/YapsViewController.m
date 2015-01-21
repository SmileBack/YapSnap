//
//  ContactsViewController.m
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


@interface YapsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *yaps;
@property (nonatomic, strong) PlaybackVC *playbackVC;

@end

static NSString *CellIdentifier = @"Cell";

@implementation YapsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Your Yaps";
    
    // TEXT COLOR OF UINAVBAR
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = THEME_RED_COLOR;
    
    self.navigationItem.hidesBackButton = YES;

    __weak YapsViewController *weakSelf = self;
    [[API sharedAPI] getYapsWithCallback:^(NSArray *yaps, NSError *error) {
        if (yaps) {
            weakSelf.yaps = yaps;
            [weakSelf.tableView reloadData];
        } else {
            NSLog(@"Error! %@", error);
        }
    }];

//    [[NSNotificationCenter defaultCenter] addObserverForName:PLAYBACK_STOPPED_NOTIFICATION
//                                                      object:nil
//                                                       queue:nil
//                                                  usingBlock:^(NSNotification *note) {
//                                                      [self.playbackVC.view removeFromSuperview];
//                                                      [self.playbackVC removeFromParentViewController];
//                                                      self.playbackVC = nil;
//                                                  }];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
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
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap* yap = self.yaps[indexPath.row];

    BOOL didSendYap = [yap.senderID isEqual:[Global retrieveValueForKey:@"current_user_id"]];
    NSString *cellType = didSendYap ? @"Sent Cell" : @"Received Cell";
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    if (didSendYap) {
        cell.nameLabel.text = yap.displayReceiverName;
        if ([yap.status  isEqual: @"unopened"]) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"Sent %@ | Delivered" , yap.createdAt.description];
        } else if ([yap.status  isEqual: @"opened"]) {
            cell.createdTimeLabel.text = [NSString stringWithFormat:@"Sent %@ | Opened" , yap.createdAt.description];
        }
    } else {
        cell.nameLabel.text = yap.displaySenderName;
        cell.createdTimeLabel.text = [NSString stringWithFormat:@"Received %@" , yap.createdAt.description];
        if ([yap.type  isEqual: @"SpotifyMessage"]) {
            UIButton *spotifyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [spotifyButton addTarget:self
                              action:@selector(tappedListenOnSpotifyButton)
                    forControlEvents:UIControlEventTouchUpInside];
            [spotifyButton setBackgroundImage:[UIImage imageNamed:@"listen_on_spotify-black.png"] forState:UIControlStateNormal];
            spotifyButton.frame = CGRectMake(223, 18, 89, 33);
            [cell addSubview:spotifyButton];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRow");
    
    YSYap *yap = self.yaps[indexPath.row];
    [self performSegueWithIdentifier:@"Playback Segue" sender:yap];
}

//- (void)doDoubleTap
//{
//    NSLog(@"Double Tapped Row");
//    [Global storeValue:@"3475238941" forKey:@"reply_recipient"];
//    [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self]; // UNDO
//}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Playback Segue" isEqualToString:segue.identifier]) {
        PlaybackVC *vc = segue.destinationViewController;
        YSYap *yap = sender;
        vc.yap = yap;
    }
}

- (void) tappedListenOnSpotifyButton {
    NSLog(@"tappedListenOnSpotifyButton");
}



@end
