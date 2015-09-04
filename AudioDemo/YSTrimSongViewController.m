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
#import "UIImageView+AudioPlot.h"

#define SECONDS_PER_CLIP 12.0f

@interface YSTrimSongViewController ()<UIScrollViewDelegate>

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *artistLabel;
@property (strong, nonatomic) UIImageView *artworkImageView;
@property (strong, nonatomic) UIScrollView *timeScrollView;
@property (strong, nonatomic) UIView *leftBar;
@property (strong, nonatomic) UIView *rightBar;
@property (strong, nonatomic) UIView *playbackBar;
@property (strong, nonatomic) UIActivityIndicatorView *uploadSpinner;
@property (strong, nonatomic) YSITunesTrack *itunesTrack;
@property (strong, nonatomic) NSTimer *playbackTimer;
@property (strong, nonatomic) NSLayoutConstraint *playbackXConstraint;

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
    self.playbackBar = UIView.new;
    
    self.titleLabel.text = self.iTunesUpload.songName;
    self.artistLabel.text = self.iTunesUpload.artistName;
    self.artworkImageView.image = self.iTunesUpload.artworkImage;
    
    for (UILabel *label in @[self.titleLabel, self.artistLabel]) {
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    self.artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.timeScrollView.backgroundColor = UIColor.clearColor;
    self.timeScrollView.showsHorizontalScrollIndicator = NO;
    self.timeScrollView.
    self.timeScrollView.delegate = self;
    
    self.playbackBar.backgroundColor = UIColor.redColor;
    
    // Constraints
    for (UIView* view in @[self.titleLabel, self.artistLabel, self.artworkImageView, self.timeScrollView, self.leftBar, self.rightBar, self.playbackBar]) {
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:view];
    }
    
    for (UIView *view in @[self.titleLabel, self.artistLabel, self.artworkImageView, self.timeScrollView]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[v]-|" options:0 metrics:nil views:@{@"v": view}]];
    }
    
    for (UIView *view in @[self.leftBar, self.rightBar]) {
        view.backgroundColor = UIColor.whiteColor;
        NSLayoutAttribute xAttribute = view == self.leftBar ? NSLayoutAttributeLeft : NSLayoutAttributeRight;
        NSLayoutAttribute xOffset = view == self.leftBar ? 20 : -20;
        [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:10],
                                    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:NSLayoutAttributeHeight multiplier:1.2 constant:0],
                                    [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                    [NSLayoutConstraint constraintWithItem:view attribute:xAttribute relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:xAttribute multiplier:1.0 constant:xOffset]
                                    ]];
    }
    
    self.playbackXConstraint = [NSLayoutConstraint constraintWithItem:self.playbackBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.leftBar attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:self.playbackBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:2],
                                [NSLayoutConstraint constraintWithItem:self.playbackBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:NSLayoutAttributeHeight multiplier:1.2 constant:0],
                                [NSLayoutConstraint constraintWithItem:self.playbackBar attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                self.playbackXConstraint
                                ]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-[title]-[artist]-[image(200)]-[scroll(50)]" options:0 metrics:nil views:@{@"top": self.topLayoutGuide, @"title": self.titleLabel, @"artist": self.artistLabel, @"image": self.artworkImageView, @"scroll": self.timeScrollView}]];

    
    UIImageView *plot = [UIImageView imageViewWithAudioUrl:self.iTunesUpload.trackURL];
    [plot setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.timeScrollView addSubview:plot];
    [self.timeScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": plot}]];
    [self.timeScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:@{@"v": plot}]];
    [self.timeScrollView addConstraint:[NSLayoutConstraint constraintWithItem:plot attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.timeScrollView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    CGFloat distance = CGRectGetWidth(self.view.frame);
    CGFloat pointsPerSecond = distance / SECONDS_PER_CLIP;
    CGFloat widthOfContent = self.iTunesUpload.trackDuration * pointsPerSecond;
    [self.timeScrollView addConstraint:[NSLayoutConstraint constraintWithItem:plot attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:widthOfContent]];
}

- (void)viewDidAppear:(BOOL)animated {
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updatePlaybackBar) userInfo:nil repeats:YES];
    [self.playbackTimer fire];
    // TODO: Start audio
    [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.playbackTimer invalidate];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.playbackTimer invalidate];
    // TODO: Stop playback
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self resetPlayback];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetPlayback];
}

#pragma mark - Playback

- (void)updatePlaybackBar {
    self.playbackXConstraint.constant = self.playbackXConstraint.constant + 1;
    [self.view layoutIfNeeded];
    if (CGRectGetMaxX(self.playbackBar.frame) > CGRectGetMaxX(self.rightBar.frame)) {
        // TODO: Stop audio
        [self.playbackTimer invalidate];
    }
}

- (void)resetPlayback {
    // TODO: Start playback at given point
    self.playbackXConstraint.constant = 0;
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updatePlaybackBar) userInfo:nil repeats:YES];
    [self.playbackTimer fire];
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
