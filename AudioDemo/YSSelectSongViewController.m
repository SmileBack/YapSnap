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

#define TRIM_SEGUE @"Trim Segue"

@interface YSSelectSongViewController ()

@end

@implementation YSSelectSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:TRIM_SEGUE]) {
        YSTrimSongViewController *vc = segue.destinationViewController;
        YSiTunesUpload *upload = sender;
        vc.iTunesUpload = upload;
    }
}

#pragma mark - Actions

- (IBAction)didPressCancel:(UIBarButtonItem *)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) pickSongs:(id)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;
    picker.prompt = NSLocalizedString (@"Add songs to play",
                       "Prompt in media item picker");
    picker.showsCloudItems = NO;

    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

- (IBAction)didPressNext:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:TRIM_SEGUE sender:nil];
}

#pragma mark - MediaPickerDelegate
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker
   didPickMediaItems: (MPMediaItemCollection *) collection {
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
    
    __weak YSSelectSongViewController *weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf performSegueWithIdentifier:TRIM_SEGUE sender:upload];
    }];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end
