//
//  YSSongGroupController.m
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSongGroupController.h"
#import "YTTrackGroup.h"
#import "SongGroupCollectionViewCell.h"
#import "YSSpotifySourceController.h"

@interface YSSongGroupController()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSArray *trackGroups;
@property (strong, nonatomic) UICollectionView *collectionView;

@end

@implementation YSSongGroupController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.trackGroups = @[
                         [YTTrackGroup trackGroupWithName:@"Trending"
                                                apiString:@"trending_tracks"],
                         [YTTrackGroup trackGroupWithName:@"Funny"
                                                apiString:@"funny_tracks"],
                         [YTTrackGroup trackGroupWithName:@"Classics"
                                                apiString:@"nostalgic_tracks"],
                         [YTTrackGroup trackGroupWithName:@"Flirty"
                                                apiString:@"flirtatious_tracks"],
                         [YTTrackGroup trackGroupWithName:@"Fun"
                                                apiString:@"flirtatious_tracks"],
                         [YTTrackGroup trackGroupWithName:@"Rowdy"
                                                apiString:@"flirtatious_tracks"]
                         ];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 2;
    flowLayout.minimumLineSpacing = 2;
    flowLayout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
    if (IS_IPHONE_6_PLUS_SIZE) {
        flowLayout.itemSize = CGSizeMake(200, 230);
    } else if (IS_IPHONE_6_SIZE) {
        flowLayout.itemSize = CGSizeMake(184, 220);
    } else {
        flowLayout.itemSize = CGSizeMake(152, 180);
    }
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[SongGroupCollectionViewCell class]
            forCellWithReuseIdentifier:@"group"];
    
    [self.view addSubview:self.collectionView];
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.collectionView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][v][bottom]" options:0 metrics:nil views:@{@"v": self.collectionView, @"top": self.topLayoutGuide, @"bottom": self.bottomLayoutGuide}]];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.trackGroups.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SongGroupCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"group" forIndexPath:indexPath];
    cell.label.text = ((YTTrackGroup *)self.trackGroups[indexPath.row]).name;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    YSSpotifySourceController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    vc.trackGroup = self.trackGroups[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
