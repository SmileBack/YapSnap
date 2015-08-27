//
//  YSSelectSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSelectSongViewController.h"

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
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end
