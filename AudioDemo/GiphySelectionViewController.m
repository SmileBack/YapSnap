//
//  GiphySelectionViewController.m
//  YapTap
//
//  Created by Rudd Taylor on 1/15/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

#import "GiphySelectionViewController.h"
#import "UICollectionViewFlowLayout+YS.h"
#import "GifCell.h"

@interface GiphySelectionViewController ()<UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong) NSArray *gifs;

@end

@implementation GiphySelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDismiss)];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout appLayout]];
    self.collectionView.backgroundColor = THEME_BACKGROUND_COLOR;
    [self.collectionView registerClass:[GifCell class] forCellWithReuseIdentifier:@"Gif"];
    self.collectionView.dataSource = self;
    
    // Constraints
    [self.view addSubview:self.collectionView];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][v][bottom]" options:0 metrics:nil views:@{@"top": self.topLayoutGuide, @"v": self.collectionView, @"bottom": self.bottomLayoutGuide}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.collectionView}]];
    self.gifs = @[@"foo"];
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Gif" forIndexPath:indexPath];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.gifs.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - Actions

- (void)didTapDismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
