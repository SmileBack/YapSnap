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

typedef NS_ENUM(NSInteger, GiphySection) {
    GiphySectionLoading = 0,
    GiphySectionGifs,
    GiphySectionEmpty
};

@interface GiphySelectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong) NSArray *gifs;
@property (strong) UISearchBar *searchBar;
@property BOOL loading;

@end

@implementation GiphySelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AXCGiphy setGiphyAPIKey:kGiphyPublicAPIKey];
    [self searchForTerm];
    
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
    if (indexPath.section == GiphySectionLoading) {
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
    } else if (indexPath.section == GiphySectionGifs) {
        GifCell *cell = (GifCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Gif" forIndexPath:indexPath];
        AXCGiphy * gif = self.gifs[indexPath.item];
        [cell.gifView sd_setImageWithURL:gif.originalImage.url];
        return cell;
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Loading" forIndexPath:indexPath];
        [[cell viewWithTag:888] removeFromSuperview];
        UILabel *label = UILabel.new;
        label.text = @"No results found.\nTap above to search for gifs.";
        label.numberOfLines = 0;
        label.font = [UIFont fontWithName:@"Futura-Medium" size:20];
        label.adjustsFontSizeToFitWidth = YES;
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 888;
        [cell addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [cell addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                               [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]
                               ]];
        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == GiphySectionLoading) {
        return self.loading ? 1 : 0;
    } else if (section == GiphySectionGifs) {
        return self.gifs.count;
    } else {
        return self.gifs.count == 0 ? 1 : 0;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AXCGiphy * gif = self.gifs[indexPath.item];
    self.yapBuilder.giphyImageId = gif.gifID;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}

#pragma mark - UISearchBarDelegate

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.gifs = nil;
    self.searchTerm = searchBar.text;
    [self searchForTerm];
}

- (void)searchForTerm {
    self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout screenWidthLayout];
    self.loading = YES;
    [self.collectionView reloadData];
    [AXCGiphy searchGiphyWithTerm:self.searchTerm limit:10 offset:0 completion:^(NSArray *results, NSError *error) {
        self.loading = NO;
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
