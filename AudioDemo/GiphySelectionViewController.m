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
#import <SDWebImage/UIImageView+WebCache.h>
#import <Giphy-iOS/AXCGiphy.h>

@interface GiphySelectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong) NSArray *gifs;
@property (strong) UISearchBar *searchBar;

@end

@implementation GiphySelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AXCGiphy setGiphyAPIKey:kGiphyPublicAPIKey];
    [AXCGiphy searchGiphyWithTerm:self.searchTerm limit:10 offset:0 completion:^(NSArray *results, NSError *error) {
        self.gifs = results;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.collectionView reloadData];
        }];
    }];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDismiss)];
    self.navigationItem.title = @"Select a Gif";
    
    self.searchBar = [[UISearchBar alloc] init];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout appLayout]];
    self.collectionView.backgroundColor = THEME_BACKGROUND_COLOR;
    [self.collectionView registerClass:[GifCell class] forCellWithReuseIdentifier:@"Gif"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    // Constraints
    for (UIView *view in @[self.collectionView, self.searchBar]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": view}]];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][search][v][bottom]" options:0 metrics:nil views:@{@"top": self.topLayoutGuide, @"v": self.collectionView, @"bottom": self.bottomLayoutGuide, @"search": self.searchBar}]];
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GifCell *cell = (GifCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Gif" forIndexPath:indexPath];
    AXCGiphy * gif = self.gifs[indexPath.item];
    [cell.gifView sd_setImageWithURL:gif.originalImage.url];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.gifs.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AXCGiphy * gif = self.gifs[indexPath.item];
    self.yapBuilder.giphyImage = gif.originalImage.url;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - Actions

- (void)didTapDismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
