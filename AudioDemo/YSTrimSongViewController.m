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
#import <StreamingKit/STKAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "YSSpinnerView.h"

#define SECONDS_PER_CLIP 12.0f

@interface YSTrimSongViewController ()<UIScrollViewDelegate>

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) UIImageView *artworkImageView;
@property (strong, nonatomic) UIScrollView *timeScrollView;
@property (strong, nonatomic) UIView *leftBar;
@property (strong, nonatomic) UIView *rightBar;
@property (strong, nonatomic) UIView *playbackBar;
@property (strong, nonatomic) YSITunesTrack *itunesTrack;
@property (strong, nonatomic) NSTimer *playbackTimer;
@property (strong, nonatomic) NSLayoutConstraint *playbackXConstraint;
@property (strong, nonatomic) YSSpinnerView *spinner;
@property BOOL didSelectTrack;

@end

@implementation YSTrimSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[AVPlayer alloc] initWithURL:self.iTunesUpload.trackURL];
    self.view.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0];
    [[AVAudioSession sharedInstance]
     setCategory:AVAudioSessionCategoryPlayAndRecord
     withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
     error:nil];
    self.artworkImageView = UIImageView.new;
    self.timeScrollView = UIScrollView.new;
    self.leftBar = UIView.new;
    self.rightBar = UIView.new;
    self.playbackBar = UIView.new;
    
    self.artworkImageView.image = self.iTunesUpload.artworkImage ? self.iTunesUpload.artworkImage : [UIImage imageNamed:@"CancelImageWhite3"];
    
    self.artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.timeScrollView.backgroundColor = UIColor.clearColor;
    self.timeScrollView.showsHorizontalScrollIndicator = NO;
    self.timeScrollView.delegate = self;
    
    self.playbackBar.backgroundColor = [UIColor yellowColor];
    
    // Constraints
    for (UIView* view in @[self.artworkImageView, self.timeScrollView, self.leftBar, self.rightBar, self.playbackBar]) {
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:view];
    }
    
    for (UIView *view in @[self.artworkImageView]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[v]-|" options:0 metrics:nil views:@{@"v": view}]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.artworkImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.artworkImageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    }
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.timeScrollView}]];
    
    for (UIView *view in @[self.leftBar, self.rightBar]) {
        view.backgroundColor = THEME_RED_COLOR;
        NSLayoutAttribute xAttribute = view == self.leftBar ? NSLayoutAttributeLeft : NSLayoutAttributeRight;
        NSLayoutAttribute xOffset = view == self.leftBar ? 20 : -20;
        [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:2],
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
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top]-[image]-(30)-[scroll(50)]" options:0 metrics:nil views:@{@"top": self.topLayoutGuide, @"image": self.artworkImageView, @"scroll": self.timeScrollView}]];
    
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
    [self.view layoutIfNeeded];
    self.timeScrollView.contentInset = UIEdgeInsetsMake(0, CGRectGetMaxX(self.leftBar.frame), 0, CGRectGetMaxX(self.leftBar.frame));
}

- (void)viewWillAppear:(BOOL)animated {
    [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
    self.timeScrollView.contentOffset = CGPointMake(-CGRectGetMaxX(self.leftBar.frame), 0); // This triggers the playback view moving
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.spinner removeFromSuperview];
    self.spinner = nil;
    [self.player pause];
    [self.playbackTimer invalidate];
    if (!self.didSelectTrack) {
        [self cancelPlayingAudio];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self resetPlaybackTimer];
    [self.player pause];
}

- (NSTimeInterval)secondsForContentOffset:(CGPoint)offset {
    return (self.timeScrollView.contentOffset.x/self.timeScrollView.contentSize.width) * self.iTunesUpload.trackDuration;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self resetPlaybackTimer];
    [self.player seekToTime:CMTimeMakeWithSeconds([self secondsForContentOffset:self.timeScrollView.contentOffset], NSEC_PER_SEC)];
    [self.player play];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetPlaybackTimer];
    [self.player seekToTime:CMTimeMakeWithSeconds([self secondsForContentOffset:self.timeScrollView.contentOffset], NSEC_PER_SEC)];
    [self.player play];
}

#pragma mark - Playback

- (void)updatePlaybackBar {
    self.playbackXConstraint.constant = self.playbackXConstraint.constant + 1;
    [self.view layoutIfNeeded];
    if (CGRectGetMaxX(self.playbackBar.frame) > CGRectGetMaxX(self.rightBar.frame)) {
        [self.player pause];
        [self.playbackTimer invalidate];
    }
}

- (void)resetPlaybackTimer  {
    // TODO: Start playback at given point
    [self.playbackTimer invalidate];
    self.playbackXConstraint.constant = 0;
    CGFloat width = CGRectGetMaxX(self.rightBar.frame) - CGRectGetMaxX(self.leftBar.frame);
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:SECONDS_PER_CLIP/width target:self selector:@selector(updatePlaybackBar) userInfo:nil repeats:YES];
}

#pragma mark - Trim And Upload
- (void)trim {
    __weak YSTrimSongViewController *weakSelf = self;
    self.iTunesUpload.startTime = [self secondsForContentOffset:self.timeScrollView.contentOffset];
    self.iTunesUpload.endTime = [self secondsForContentOffset:self.timeScrollView.contentOffset] + SECONDS_PER_CLIP;

    YSSongTrimmer *trimmer = [YSSongTrimmer songTrimmerWithSong:self.iTunesUpload];

    [trimmer trim:^(NSString *url, NSError *error) {
        NSURL *theURL = [NSURL URLWithString:url];
        if (theURL) {
            [weakSelf uploadSongClip:theURL];
        } else {
            [weakSelf.spinner removeFromSuperview];
        }
    }];
}

- (NSURL *)saveImage {
    if (self.iTunesUpload.artworkImage) {
        NSData *pngData = UIImagePNGRepresentation(self.iTunesUpload.artworkImage);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *imageName = [NSString stringWithFormat:@"image_%d.png", arc4random() % 1000];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES];
        return [NSURL fileURLWithPath:filePath];
    } else {
        return nil;
    }
}

- (void)uploadArtwork {
    NSLog(@"Uploading artwork.");
    NSURL *url = [self saveImage];
    if (url) {
        __weak YSTrimSongViewController *weakSelf = self;
        AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
        [amazonAPI uploadiTunesArtwork:url
                          withCallback:^(NSString *url, NSString *etag, NSError *error) {
                              if (error) {
                                  // TODO
                                  [self.spinner removeFromSuperview];
                              } else {
                                  weakSelf.iTunesUpload.awsAlbumImageUrl = url;
                                  weakSelf.iTunesUpload.awsAlbumImageEtag = etag;
                                  [weakSelf uploadToBackend];
                              }
                          }];
    } else {
        [self uploadToBackend];
    }
}

- (void)uploadSongClip:(NSURL *)url {
    NSLog(@"Uploading song clip.");
    __weak YSTrimSongViewController *weakSelf = self;

    AmazonAPI *amazonAPI = [AmazonAPI sharedAPI];
    [amazonAPI uploadiTunesTrack:url
                    withCallback:^(NSString *url, NSString *etag, NSError *error) {
                        if (error) {
                            // TODO
                            [self.spinner removeFromSuperview];
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
                        [self.spinner removeFromSuperview];
                        self.spinner = nil;
                        if (error) {
                            // TODO
                        } else {
                            self.itunesTrack = self.iTunesUpload;
                            [self.audioCaptureDelegate audioSourceControllerIsReadyToProduceYapBuidler:self];
                        }
                    }];
}

#pragma mark - Audio Source

#pragma mark - Implement public audio methods

- (void)prepareYapBuilder {
    self.didSelectTrack = YES;
    [self.spinner removeFromSuperview];
    self.spinner = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:self.spinner];
    self.spinner.center = self.view.center;
    [self trim];
}

- (NSString *)currentAudioDescription {
    return self.iTunesUpload.songName;
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
    yapBuilder.duration = SECONDS_PER_CLIP;
    yapBuilder.messageType = MESSAGE_TYPE_ITUNES;
    YSTrack *track = [YSTrack trackFromiTunesTrack:self.iTunesUpload];
    yapBuilder.track = track;
    yapBuilder.awsVoiceEtag = self.itunesTrack.awsSongEtag;
    yapBuilder.awsVoiceURL = self.itunesTrack.awsSongUrl;
    yapBuilder.yapImageAwsEtag = self.itunesTrack.awsAlbumImageEtag;
    //yapBuilder.track.albumImageURL = self.itunesTrack.awsArtworkUrl;
    return yapBuilder;
}

@end
