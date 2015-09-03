//
//  YSTrimSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSTrimSongViewController.h"
#import "YSSongTrimmer.h"
#import "API.h"
#import "AmazonAPI.h"

#define SECONDS_PER_CLIP 12.0f

@interface YSTrimSongViewController ()

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *artistLabel;
@property (strong, nonatomic) UIImageView *artworkImageView;
@property (strong, nonatomic) UIScrollView *timeScrollView;
@property (strong, nonatomic) UIView *leftBar;
@property (strong, nonatomic) UIView *rightBar;
@property (strong, nonatomic) UIActivityIndicatorView *uploadSpinner;

@end

@implementation YSTrimSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0];
    
    self.titleLabel = UILabel.new;
    self.artistLabel = UILabel.new;
    self.artworkImageView = UIImageView.new;
    self.timeScrollView = UIScrollView.new;
    self.leftBar = UIView.new;
    self.rightBar = UIView.new;

    for (UILabel *label in @[self.titleLabel, self.artistLabel]) {
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    self.artworkImageView.contentMode = UIViewContentModeScaleAspectFit;

    // Constraints
    for (UIView* view in @[self.titleLabel, self.artistLabel, self.artworkImageView, self.timeScrollView, self.leftBar, self.rightBar]) {
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:view];
    }
    
    for (UIView *view in @[self.titleLabel, self.artistLabel, self.artworkImageView, self.timeScrollView]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[v]-|" options:0 metrics:nil views:@{@"v": view}]];
    }
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-[title]-[artist]-[image(200)]-[scroll(50)]" options:0 metrics:nil views:@{@"top": self.topLayoutGuide, @"title": self.titleLabel, @"artist": self.artistLabel, @"image": self.artworkImageView, @"scroll": self.timeScrollView}]];
    
    self.titleLabel.text = self.iTunesUpload.songName;
    self.artistLabel.text = self.iTunesUpload.artistName;
    self.artworkImageView.image = self.iTunesUpload.artworkImage;

    CGFloat distance = self.rightBar.frame.origin.x - self.leftBar.frame.origin.x;
    CGFloat pointsPerSecond = distance / SECONDS_PER_CLIP;
    CGFloat widthOfContent = self.iTunesUpload.trackDuration * pointsPerSecond;
    self.timeScrollView.contentSize = CGSizeMake(widthOfContent, 54);
    self.timeScrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    
    UIView *innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, widthOfContent, 44)];
    [self.timeScrollView addSubview:innerView];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
}

#pragma mark - Trim And Upload
- (void)trim {
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
            [self.uploadSpinner stopAnimating];
        }
    }];
}

- (NSURL *)saveImage {
    NSData *pngData = UIImagePNGRepresentation(self.iTunesUpload.artworkImage);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *imageName = [NSString stringWithFormat:@"image_%d.png", arc4random() % 1000];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
    [pngData writeToFile:filePath atomically:YES];
    return [NSURL fileURLWithPath:filePath];
}

- (void)uploadArtwork {
    NSLog(@"Uploading artwork.");
    NSURL *url = [self saveImage];
    __weak YSTrimSongViewController *weakSelf = self;
    AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
    [amazonAPI uploadiTunesArtwork:url
                      withCallback:^(NSString *url, NSString *etag, NSError *error) {
                          if (error) {
                              // TODO
                              [self.uploadSpinner stopAnimating];
                          } else {
                              weakSelf.iTunesUpload.awsArtworkUrl = url;
                              weakSelf.iTunesUpload.awsArtworkEtag = etag;
                              [weakSelf uploadToBackend];
                          }
                      }];
}

- (void)uploadSongClip:(NSURL *)url {
    NSLog(@"Uploading song clip.");
    __weak YSTrimSongViewController *weakSelf = self;

    AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
    [amazonAPI uploadiTunesTrack:url
                    withCallback:^(NSString *url, NSString *etag, NSError *error) {
                        if (error) {
                            // TODO
                            [self.uploadSpinner stopAnimating];
                        } else {
                            weakSelf.iTunesUpload.awsSongUrl = url;
                            weakSelf.iTunesUpload.awsSongEtag = etag;
                            [weakSelf uploadArtwork];
                        }
                    }];
}

- (void)uploadToBackend {
    NSLog(@"Uploading to backend.");

    API *sharedAPI = [API sharedAPI];
    [sharedAPI uploadItunesTrack:self.iTunesUpload
                    withCallback:^(YSITunesTrack *itunesTrack, NSError *error) {
                        if (error) {
                            // TODO
                            [self.uploadSpinner stopAnimating];
                        } else {
                            [self.audioCaptureDelegate audioSourceControllerIsReadyToProduceYapBuidler:self];
                        }
                    }];
}

#pragma mark - Audio Source

#pragma mark - Implement public audio methods

- (void)prepareYapBuilder {
    [self.uploadSpinner startAnimating];
    [self trim];
}

- (NSString *)currentAudioDescription {
    return self.titleLabel.text;
}

- (BOOL)startAudioCapture {
    return YES;
}

- (void)cancelPlayingAudio {
    [self.audioCaptureDelegate audioSourceControllerdidCancelAudioCapture:self];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)stopAudioCapture {
    [self.audioCaptureDelegate audioSourceControllerdidFinishAudioCapture:self];
}

- (YapBuilder *) getYapBuilder {
    YapBuilder *yapBuilder = [[YapBuilder alloc] init];
    // TODO: Configure Yap builder
    return yapBuilder;
}

@end
