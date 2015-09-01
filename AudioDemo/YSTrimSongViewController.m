//
//  YSTrimSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSTrimSongViewController.h"
#import "YSITunesConfirmViewController.h"
#import "YSSongTrimmer.h"
#import "API.h"
#import "AmazonAPI.h"

#define CONFIRM_SEGUE @"Confirm Segue"

#define SECONDS_PER_CLIP 12.0f

@interface YSTrimSongViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *timeScrollView;
@property (strong, nonatomic) IBOutlet UIView *leftBar;
@property (strong, nonatomic) IBOutlet UIView *rightBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *uploadSpinner;

@end

@implementation YSTrimSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = self.iTunesUpload.songName;
    self.artistLabel.text = self.iTunesUpload.artistName;
    self.artworkImageView.image = self.iTunesUpload.artworkImage;
    
    [self setupScrollView];
}

- (void) setupScrollView
{
    CGFloat distance = self.rightBar.frame.origin.x - self.leftBar.frame.origin.x;
    CGFloat pointsPerSecond = distance / SECONDS_PER_CLIP;
    CGFloat widthOfContent = self.iTunesUpload.trackDuration * pointsPerSecond;
    self.timeScrollView.contentSize = CGSizeMake(widthOfContent, 54);
    self.timeScrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    
    UIView *innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, widthOfContent, 44)];
    innerView.backgroundColor = [UIColor blueColor];
    [self.timeScrollView addSubview:innerView];
}

#pragma mark - Progress
- (void) startTrimAndUploadUI
{
    self.uploadButton.enabled = NO;
    [self.uploadSpinner startAnimating];
}

- (void) stoppedTrimAndUploadUI
{
    self.uploadButton.enabled = YES;
    [self.uploadSpinner stopAnimating];
}

#pragma mark - Trim And Upload
- (void) trim
{
    __weak YSTrimSongViewController *weakSelf = self;

    // TODO HACK
    self.iTunesUpload.startTime = 0.0f;
    self.iTunesUpload.endTime = 12.0f;
    
    YSSongTrimmer *trimmer = [YSSongTrimmer songTrimmerWithSong:self.iTunesUpload];
    
    [trimmer trim:^(NSString *url, NSError *error) {
        NSURL *theURL = [NSURL URLWithString:url];
        if (url) {
            [weakSelf uploadSongClip:theURL];
        } else {
            [self stoppedTrimAndUploadUI];
        }
    }];

}

- (NSURL *)saveImage
{
    NSData *pngData = UIImagePNGRepresentation(self.iTunesUpload.artworkImage);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *imageName = [NSString stringWithFormat:@"image_%d.png", arc4random() % 1000];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
    [pngData writeToFile:filePath atomically:YES];
    return [NSURL fileURLWithPath:filePath];
}

- (void) uploadArtwork
{
    NSLog(@"Uploading artwork.");
    NSURL *url = [self saveImage];
    __weak YSTrimSongViewController *weakSelf = self;
    AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
    [amazonAPI uploadiTunesArtwork:url
                      withCallback:^(NSString *url, NSString *etag, NSError *error) {
                          if (error) {
                              // TODO
                              [weakSelf stoppedTrimAndUploadUI];
                          } else {
                              weakSelf.iTunesUpload.awsArtworkUrl = url;
                              weakSelf.iTunesUpload.awsArtworkEtag = etag;
                              [weakSelf uploadToBackend];
                          }
                      }];
}

- (void) uploadSongClip:(NSURL *)url
{
    NSLog(@"Uploading song clip.");
    __weak YSTrimSongViewController *weakSelf = self;

    AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
    [amazonAPI uploadiTunesTrack:url
                    withCallback:^(NSString *url, NSString *etag, NSError *error) {
                        if (error) {
                            // TODO
                            [self stoppedTrimAndUploadUI];
                        } else {
                            weakSelf.iTunesUpload.awsSongUrl = url;
                            weakSelf.iTunesUpload.awsSongEtag = etag;
                            [weakSelf uploadArtwork];
                        }
                    }];
}

- (void) uploadToBackend
{
    NSLog(@"Uploading to backend.");

    API *sharedAPI = [API sharedAPI];
    [sharedAPI uploadItunesTrack:self.iTunesUpload
                    withCallback:^(YSITunesTrack *itunesTrack, NSError *error) {
                        if (error) {
                            // TODO
                            [self stoppedTrimAndUploadUI];
                        } else {
                            NSLog(@"Success!");
                        }
                    }];
}

#pragma mark - Actions
- (IBAction)didPressUpload:(UIBarButtonItem *)sender
{
    [self startTrimAndUploadUI];
    [self trim];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:CONFIRM_SEGUE]) {
        YSITunesConfirmViewController *confirmVC = segue.destinationViewController;
        YSiTunesUpload *upload = sender;
        confirmVC.iTunesUpload = upload;
    }
}

#pragma mark - UISCrollViewDelegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

@end
