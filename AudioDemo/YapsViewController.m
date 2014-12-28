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

#import "MusicPlaybackVC.h"


@interface YapsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *yaps;
@property (nonatomic, strong) MusicPlaybackVC *playbackVC;
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

    [[NSNotificationCenter defaultCenter] addObserverForName:@"Playback stopped"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.playbackVC.view removeFromSuperview];
                                                      [self.playbackVC removeFromParentViewController];
                                                      self.playbackVC = nil;
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
    return 65;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:simpleTableIdentifier];
    }
    
    YSYap* yap = self.yaps[indexPath.row];
    
    if ([yap.senderID isEqual:[Global retrieveValueForKey:@"current_user_id"]]){
        cell.textLabel.text = [yap.receiverName isKindOfClass:[NSNull class]] ? @"no receiver" : yap.receiverName;
    } else {
        cell.textLabel.text = [yap.senderName isKindOfClass:[NSNull class]] ? @"no sender" : yap.senderName;
    }
    
    UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
    longPress.minimumPressDuration = 0;
    longPress.allowableMovement = 50;
    [longPress addTarget:self action:@selector(isPressingLong:)];
    [cell.contentView addGestureRecognizer:longPress];
    
    
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

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"didSelectRow");
    
//    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:   self action:@selector(doDoubleTap)];
//    doubleTap.numberOfTapsRequired = 2;
//    [self.view addGestureRecognizer:doubleTap];
//}

- (void)doDoubleTap
{
    NSLog(@"Double Tapped Row");
    [Global storeValue:@"3475238941" forKey:@"reply_recipient"];
    [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self]; // UNDO
}

- (void) tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"didHighlight");
//    longPress addTarget:self action:<#(SEL)#>
//    [self performSegueWithIdentifier:@"Show Playback Segue" sender:longPress];
}

- (void) tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"didUnHighlight");
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UILongPressGestureRecognizer *longPress = sender;
    MusicPlaybackVC *vc = segue.destinationViewController;
    [vc.view addGestureRecognizer:longPress];
//    vc.longPress = longPress;
}

- (void) isPressingLong:(UILongPressGestureRecognizer *)gest
{
    if (gest.state == UIGestureRecognizerStateBegan) {
        self.playbackVC = [self.storyboard instantiateViewControllerWithIdentifier:@"playYapVC"];
        self.playbackVC.yap = self.yaps[0];//TODO FIX THIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.playbackVC.view.frame = self.view.frame;
//        [self addChildViewController:self.playbackVC];
//        UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
//        [currentWindow addSubview:self.playbackVC.view];
//        self.navigationController.navigationBar.alpha = 0;
//        self.navigationItem
        [self.navigationController.view addSubview:self.playbackVC.view];
//        [self.navigationController.view insertSubview:self.playbackVC.view atIndex:self.navigationController.view.subviews.count];
    } else if (gest.state == UIGestureRecognizerStateEnded) {
//        self.navigationController.navigationBarHidden = NO;
        [self.playbackVC stop];
        [self.navigationController.view sendSubviewToBack:self.playbackVC.view];
    }
}



@end
