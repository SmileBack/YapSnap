//
//  YSSelectSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSelectSongViewController.h"
#import "YSiTunesUpload.h"
#import "YSTrimSongViewController.h"
#import "UICollectionViewFlowLayout+YS.h"
#import "TrackCollectionViewCell.h"
#import "UploadCell.h"
#import "YSTrimSongViewController.h"

@interface YSSelectSongViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property UICollectionView *collectionView;

@end

@implementation YSSelectSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout appLayout]];
    [self.view addSubview:self.collectionView];
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{ @"v" : self.collectionView }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[top][v][bottom]|" options:0 metrics:nil views:@{ @"v" : self.collectionView,
                                                                                                                                     @"top" : self.topLayoutGuide,
                                                                                                                                     @"bottom" : self.bottomLayoutGuide }]];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UploadCell class]
            forCellWithReuseIdentifier:@"upload"];
    [self.collectionView registerClass:[TrackCollectionViewCell class]
            forCellWithReuseIdentifier:@"track"];
    self.collectionView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1.0];
}

#pragma mark - Actions

- (IBAction)didPressCancel:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickSongs:(id)sender {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;
    picker.prompt = NSLocalizedString(@"Add songs to play",
                                      "Prompt in media item picker");
    picker.showsCloudItems = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)didPressNext:(YSiTunesUpload *)sender {
    YSTrimSongViewController *vc = [[YSTrimSongViewController alloc] init];
    vc.iTunesUpload = sender;
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UploadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"upload" forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([[collectionView cellForItemAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"upload"]) {
        [self pickSongs:nil];
    }
}

#pragma mark - MediaPickerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker
    didPickMediaItems:(MPMediaItemCollection *)collection {
    if (collection.items.count != 1) {
        //TODO what to do if there isn't something selected?
        return;
    }
    MPMediaItem *item = collection.items[0];
    NSLog(@"Song name: %@", item.title);
    YSiTunesUpload *upload = [YSiTunesUpload new];
    upload.artistName = item.artist;
    upload.songName = item.title;
    upload.persistentID = [NSNumber numberWithLongLong:item.persistentID];
    MPMediaItemArtwork *artwork = item.artwork;
    UIImage *image = [artwork imageWithSize:artwork.imageCropRect.size];
    upload.artworkImage = image;
    upload.trackURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    upload.trackDuration = item.playbackDuration;

    [self didPressNext:upload];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
