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
#import "API.h"
#import <UIImageView+WebCache.h>
#import "YSSpinnerView.h"

@interface YSSelectSongViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property UICollectionView *collectionView;
@property NSArray *tracks;

@end

@implementation YSSelectSongViewController

@synthesize tracks = _tracks;

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

- (void)viewDidAppear:(BOOL)animated {
    [[API sharedAPI] getItunesTracks:^(NSArray *tracks, NSError *error) {
        if (error) {
            // TODO: Display error callback
        } else {
            self.tracks = tracks;
        }
    }];
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? 1 : self.tracks.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    if (indexPath.section == 0) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"upload" forIndexPath:indexPath];
    } else {
        TrackCollectionViewCell *trackCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
        YSITunesTrack *track = self.tracks[indexPath.row];
        trackCell.trackView.songNameLabel.text = track.artistName;
        if (track.awsArtworkUrl) {
            [trackCell.trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.awsArtworkUrl]];
        } else {
            trackCell.trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
        }
        
        [trackCell.trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
        [trackCell.trackView.albumImageButton addTarget:self action:@selector(didTapAlbumButton:) forControlEvents:UIControlEventTouchUpInside];
        cell = trackCell;
    }
    
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
    
    // Loading spinner
    YSSpinnerView *spinnerView = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    spinnerView.center = mediaPicker.view.center;
    [mediaPicker.view addSubview:spinnerView];
    [mediaPicker.view layoutIfNeeded];
    
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

#pragma mark - Getters/Setters

- (void)setTracks:(NSArray *)tracks {
    _tracks = tracks;
    [self.collectionView reloadData];
}

- (NSArray *)tracks {
    return _tracks;
}

@end
