//
//  YSITunesConfirmViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSITunesConfirmViewController.h"

@interface YSITunesConfirmViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *artworkImageView;
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;

@end

@implementation YSITunesConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.artworkImageView.image = self.iTunesUpload.artworkImage;
    self.songLabel.text = self.iTunesUpload.songName;
    self.artistLabel.text = self.iTunesUpload.artistName;
}

#pragma mark - Actions
- (IBAction)didPressUpload:(id)sender
{
}


@end
