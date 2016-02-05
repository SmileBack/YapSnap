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

@interface GiphySelectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong) NSArray *gifs;
@property (strong) UISearchBar *searchBar;

@end

@implementation GiphySelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AXCGiphy setGiphyAPIKey:kGiphyPublicAPIKey];
    [AXCGiphy searchGiphyWithTerm:self.searchTerm limit:10 offset:0 completion:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.gifs = results;
            self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout appLayout];
            [self.collectionView reloadData];
        });
    }];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(didTapDismiss)];
    self.navigationItem.title = @"Select a Gif";
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.text = self.searchTerm;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout screenWidthLayout]];
    self.collectionView.backgroundColor = THEME_BACKGROUND_COLOR;
    [self.collectionView registerClass:[GifCell class] forCellWithReuseIdentifier:@"Gif"];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Loading"];
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
    if (indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Loading" forIndexPath:indexPath];
        [[cell viewWithTag:888] removeFromSuperview];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.tag = 888;
        [cell addSubview:spinner];
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [cell addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]
                               ]];
        [spinner startAnimating];
        return cell;
    } else {
        GifCell *cell = (GifCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Gif" forIndexPath:indexPath];
        AXCGiphy * gif = self.gifs[indexPath.item];
        [cell.gifView sd_setImageWithURL:gif.originalImage.url];
        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return self.gifs ? 0 : 1;
    } else {
        return self.gifs.count;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AXCGiphy * gif = self.gifs[indexPath.item];
    self.yapBuilder.giphyImage = gif.originalImage.url;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

#pragma mark - UISearchBarDelegate

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.gifs = nil;
    self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout screenWidthLayout];
    [self.collectionView reloadData];
    [AXCGiphy searchGiphyWithTerm:self.searchTerm limit:10 offset:0 completion:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.gifs = results;
            self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout appLayout];
            [self.collectionView reloadData];
        });
    }];
}

#pragma mark - Actions

- (void)didTapDismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
