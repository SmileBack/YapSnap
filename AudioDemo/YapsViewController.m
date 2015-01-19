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
    return 65;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YSYap* yap = self.yaps[indexPath.row];

    BOOL didSendYap = [yap.senderID isEqual:[Global retrieveValueForKey:@"current_user_id"]];
    NSString *cellType = didSendYap ? @"Sent Cell" : @"Received Cell";
    
    YapCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    
    if (didSendYap) {
        cell.nameLabel.text = @"yap.receiverName";
    } else {
        cell.nameLabel.text = @"yap.senderName";
    }
//    NSDateFormatter
    cell.createdTimeLabel.text = yap.createdAt.description;
    
//    UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
//    longPress.minimumPressDuration = 0;
//    longPress.allowableMovement = 50;
//    [longPress addTarget:self action:@selector(isPressingLong:)];
//    [cell.contentView addGestureRecognizer:longPress];
    
    
//    if (indexPath.row == 2) {
//        cell.imageView.image = [UIImage imageNamed:@"RedArrowBackward.png"];
//    } else if (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 3 || indexPath.row == 6 ) {
//        cell.imageView.image = [UIImage imageNamed:@"BlueArrow.png"];
//    } else {
//        cell.imageView.image = [UIImage imageNamed:@"Replay.png"];
//    }
//    
//    
//    
//    cell.textLabel.text = [yaps objectAtIndex:indexPath.row];
//    cell.detailTextLabel.text = @"5 mins ago";
//    cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0f];
//    
//    if (indexPath.row == 2) {
//        UIProgressView* progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
//        progressView.frame = CGRectMake(62,62, 258,10);
//        progressView.progress = 0.4;
//        [cell.contentView addSubview:progressView];
//    }
    
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

//- (void) isPressingLong:(UILongPressGestureRecognizer *)gest
//{
//    if (gest.state == UIGestureRecognizerStateBegan) {
//        self.playbackVC = [self.storyboard instantiateViewControllerWithIdentifier:@"playYapVC"];
//        self.playbackVC.yap = self.yaps[0];//TODO FIX THIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//        self.playbackVC.view.frame = self.view.frame;
//        [self.navigationController.view addSubview:self.playbackVC.view];
//    } else if (gest.state == UIGestureRecognizerStateEnded) {
//        [self.playbackVC stop];
//        [self.navigationController.view sendSubviewToBack:self.playbackVC.view];
//    }
//}



@end
