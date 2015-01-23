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
@property (nonatomic, strong) UIRefreshControl *refreshControl;

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

    [self loadYaps];

    // Pull down to refresh
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
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
    
    cell.createdTimeLabel.text = [NSString stringWithFormat:@"%@" , yap.createdAt.description];
    
    if (didSendYap) {
        cell.nameLabel.text = yap.displayReceiverName;
    } else {
        cell.nameLabel.text = yap.displaySenderName;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRow");
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


@end
