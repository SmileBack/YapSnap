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
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 50;

    __weak FriendsViewController *weakSelf = self;
    [[API sharedAPI] friends:^(NSArray *friends, NSError *error) {
        if (error) {
            // TODO handle error
        } else {
            weakSelf.friends = friends;
            [weakSelf.tableView reloadData];
        }
    }];
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
    if (indexPath.section == 0 || [indexPath isEqual:self.selectedIndexPath]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_EXPANDED forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_COLLAPSED forIndexPath:indexPath];
    }
    
    cell.nameLabel.text = user.displayName;
    [cell.nameLabel sizeToFit];
    
//    cell.scoreLabel.text = [NSString stringWithFormat:@"%d", user.score.intValue];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return HEIGHT_EXPANDED;
    }
    
    return [indexPath isEqual:self.selectedIndexPath] ? HEIGHT_EXPANDED : HEIGHT_COLLAPSED;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return;
    }

    NSMutableArray *changedIndexPaths = [NSMutableArray array];
    [changedIndexPaths addObject:indexPath];

    [tableView beginUpdates];
    if (!self.selectedIndexPath) {
        // Nothing is selected yet. Just expand the cell.
        self.selectedIndexPath = indexPath;
    } else if ([indexPath isEqual:self.selectedIndexPath]) {
        // We clicked on the currently selected cell. Just collapse it.
        self.selectedIndexPath = nil;
    } else {
        // We're expanding this friend and closing another.
        [changedIndexPaths addObject:self.selectedIndexPath];
        self.selectedIndexPath = indexPath;
    }

    [tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [tableView endUpdates];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"You" : @"Friends";
}

@end
