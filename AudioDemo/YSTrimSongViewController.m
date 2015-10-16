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
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIViewController+MJPopupViewController.h"
#import "UploadPopupViewController.h"


#define SECONDS_PER_CLIP 14.0f

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
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UILabel *songDurationLabel;
@property BOOL didSelectTrack;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (nonatomic) int durationInSeconds;
@property (nonatomic) int minutes;
@property (nonatomic) int seconds;
@property (strong, nonatomic) UploadPopupViewController *uploadPopupVC;

#define VIEWED_UPLOAD_POPUP_KEY @"yaptap.ViewedUploadPopup8"

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
    
    [self setupNotifications];

    //[self.artworkImageView sd_setImageWithURL:[self albumImageNSURL]];
    self.artworkImageView.image = self.iTunesUpload.artworkImage ? self.iTunesUpload.artworkImage : [UIImage imageNamed:@"AlbumImagePlaceholder2"];
    
    self.artworkImageView.layer.borderWidth = 1;
    self.artworkImageView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.artworkImageView.clipsToBounds = YES;
    [self.artworkImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedImageView)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [self.artworkImageView addGestureRecognizer:tap];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedImageView)];
    [swipeRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight)];
    [self.artworkImageView addGestureRecognizer:swipeRecognizer];
    
    self.artworkImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.timeScrollView.backgroundColor = UIColor.clearColor;
    self.timeScrollView.showsHorizontalScrollIndicator = NO;
    self.timeScrollView.delegate = self;
    
    self.playbackBar.backgroundColor = [UIColor redColor];
    
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
        view.backgroundColor = [UIColor blackColor];//THEME_RED_COLOR;
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
    
    float timeLabelHeight = 80;
    float timeLabelXPosition = (self.view.frame.size.width - 300)/2;
    float timeLabelYPosition = self.artworkImageView.frame.origin.y + self.artworkImageView.frame.size.height/2 - (timeLabelHeight/2);

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelXPosition, timeLabelYPosition-10, 300, timeLabelHeight)];
    self.timeLabel.text = @"O";
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [UIFont fontWithName:@"Futura-Medium" size:90];
    self.timeLabel.adjustsFontSizeToFitWidth = NO;
    self.timeLabel.opaque = YES;
    self.timeLabel.shadowColor = [UIColor blackColor];
    self.timeLabel.shadowOffset = CGSizeMake(1, 1);
    self.timeLabel.layer.masksToBounds = NO;
    
    [self.view addSubview:self.timeLabel];
    
    
    self.songDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelXPosition, timeLabelYPosition-10+125, 300, timeLabelHeight)];
    self.songDurationLabel.text = @"O";
    self.songDurationLabel.textColor = [UIColor whiteColor];
    self.songDurationLabel.textAlignment = NSTextAlignmentCenter;
    self.songDurationLabel.font = [UIFont fontWithName:@"Futura-Medium" size:20];
    self.songDurationLabel.adjustsFontSizeToFitWidth = NO;
    self.songDurationLabel.opaque = YES;
    self.songDurationLabel.shadowColor = [UIColor blackColor];
    self.songDurationLabel.shadowOffset = CGSizeMake(.5, .5);
    self.songDurationLabel.layer.masksToBounds = NO;
    
    [self.view addSubview:self.songDurationLabel];
    
    double delay = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.didViewUploadPopup) {
            [self showUploadPopup];
        }
    });
}

- (void)viewWillAppear:(BOOL)animated {
    self.effectView.alpha = 0;
    self.timeLabel.alpha = 0;
    self.songDurationLabel.alpha = 0;
    self.view.userInteractionEnabled = YES;
    
    if (self.didViewUploadPopup) {
        [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
        self.timeScrollView.contentOffset = CGPointMake(-CGRectGetMaxX(self.leftBar.frame), 0); // This triggers the playback view moving
        NSLog(@"-CGRectGetMaxX(self.leftBar.frame: %f", -CGRectGetMaxX(self.leftBar.frame));
        [self loopSong]; // added this to fix bug where sometimes you'd go back to this page and bar would be stuck
        [self.player play];
    } else {
        //We trigger popup to be shown in the viewdidload method
        //this probably isn't necessary since audioSourceControllerWillStartAudioCapture is what causes the bar to show in the first place
        //[[NSNotificationCenter defaultCenter] postNotificationName:HIDE_BOTTOM_BAR_NOTIFICATION object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.spinner removeFromSuperview];
    self.spinner = nil;
    [self.player pause];
    [self.playbackTimer invalidate];
    if (!self.didSelectTrack) {
        [self cancelPlayingAudio];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HIDE_BOTTOM_BAR_NOTIFICATION object:nil];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    NSLog(@"View Will Disappear");
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:DISMISS_UPLOAD_POPUP_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Dismiss Upload Popup");
                        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_UPLOAD_POPUP_KEY];
                        
                        [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
                        self.timeScrollView.contentOffset = CGPointMake(-CGRectGetMaxX(self.leftBar.frame), 0); // This triggers the playback view moving
                        NSLog(@"-CGRectGetMaxX(self.leftBar.frame: %f", -CGRectGetMaxX(self.leftBar.frame));
                        [self loopSong]; // added this to fix bug where sometimes you'd go back to this page and bar would be stuck
                        [self.player play];
                    }];
}

- (void) tappedImageView {
    [[YTNotifications sharedNotifications] showNotificationText:@"Slide the Blue Wave Below!"];
}

- (void) swipedImageView {
    [[YTNotifications sharedNotifications] showNotificationText:@"Slide the Blue Wave Below!"];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self resetPlaybackTimer];
    [self.player pause];
    
    self.effectView.alpha = 1;
    self.timeLabel.alpha = 1;
    self.songDurationLabel.alpha = 1;

    self.durationInSeconds = MAX(0, ((self.timeScrollView.contentOffset.x/self.timeScrollView.contentSize.width) * self.iTunesUpload.trackDuration));
    self.minutes = self.durationInSeconds / 60;
    self.seconds = self.durationInSeconds % 60;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%d:%02d", self.minutes, self.seconds];
    /*
    int seconds = self.iTunesUpload.trackDuration % 60;
    int minutes = (self.iTunesUpload.trackDuration / 60) % 60;
    int hours = self.iTunesUpload.trackDuration / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    */
    
    int roundedNumber = ceil((double)self.iTunesUpload.trackDuration);
    NSLog(@"Duration: %f", self.iTunesUpload.trackDuration);
    NSLog(@"Rounded Duration: %d", roundedNumber);
    NSLog(@"Formatted Duration: %@", [NSString stringWithFormat:@"%d:%02d", (roundedNumber/60) % 60,(roundedNumber/60)]);
    
    self.songDurationLabel.text = [NSString stringWithFormat:@"%d:%02d", roundedNumber/60, roundedNumber % 60];
}

- (NSTimeInterval)secondsForContentOffset:(CGPoint)offset {
    NSLog(@"Seconds2: %f", (self.timeScrollView.contentOffset.x/self.timeScrollView.contentSize.width) * self.iTunesUpload.trackDuration);

    //self.timeLabel.text = [NSString stringWithFormat: @"%f", (self.timeScrollView.contentOffset.x/self.timeScrollView.contentSize.width) * self.iTunesUpload.trackDuration];
    
    return (self.timeScrollView.contentOffset.x/self.timeScrollView.contentSize.width) * self.iTunesUpload.trackDuration;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"WILL BEGIN DRAGGING");
    
    [self.effectView removeFromSuperview];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    self.effectView.frame =  CGRectMake(0, 0, 2208, 2208); // 2208 is as big as iphone plus height
    [self.artworkImageView addSubview:self.effectView];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Upload - Dragged Sound Wave"];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self resetPlaybackTimer];
    [self.player seekToTime:CMTimeMakeWithSeconds([self secondsForContentOffset:self.timeScrollView.contentOffset], NSEC_PER_SEC)];
    [self.player play];
    
    [UIView animateWithDuration:.8
                     animations:^(void) {
                         self.effectView.alpha = 0;
                     }];
    
    [UIView animateWithDuration:.5
                     animations:^(void) {
                         self.timeLabel.alpha = 0;
                         self.songDurationLabel.alpha = 0;
                     }];
    
    NSLog(@"DID END DRAGGING");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetPlaybackTimer];
    [self.player seekToTime:CMTimeMakeWithSeconds([self secondsForContentOffset:self.timeScrollView.contentOffset], NSEC_PER_SEC)];
    [self.player play];
    
    [UIView animateWithDuration:.8
                     animations:^(void) {
                         self.effectView.alpha = 0;
                     }];
    
    [UIView animateWithDuration:.5
                     animations:^(void) {
                         self.timeLabel.alpha = 0;
                         self.songDurationLabel.alpha = 0;
                     }];
}

#pragma mark - Playback

- (void)updatePlaybackBar {
    self.playbackXConstraint.constant = self.playbackXConstraint.constant + 1;
    [self.view layoutIfNeeded];
    if (CGRectGetMaxX(self.playbackBar.frame) > CGRectGetMaxX(self.rightBar.frame)) {
        [self.player pause];
        [self.playbackTimer invalidate];
        [self loopSong]; //added
    }
}

- (void)resetPlaybackTimer  {
    [self.playbackTimer invalidate];
    self.playbackXConstraint.constant = 0;
    CGFloat width = CGRectGetMaxX(self.rightBar.frame) - CGRectGetMaxX(self.leftBar.frame);
    
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:SECONDS_PER_CLIP/width target:self selector:@selector(updatePlaybackBar) userInfo:nil repeats:YES];
}

- (void)loopSong  {
    [self.playbackTimer invalidate];
    self.playbackXConstraint.constant = 0;
    CGFloat width = CGRectGetMaxX(self.rightBar.frame) - CGRectGetMaxX(self.leftBar.frame);
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:SECONDS_PER_CLIP/width target:self selector:@selector(updatePlaybackBar) userInfo:nil repeats:YES];
    
    [self.player seekToTime:CMTimeMakeWithSeconds([self secondsForContentOffset:self.timeScrollView.contentOffset], NSEC_PER_SEC)];
    [self.player play];
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
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Upload - Pressed Continue on Trim Page"];
}

- (NSURL *)albumImageNSURL {
    if (self.iTunesUpload.artworkImage) {
        NSData *pngData = UIImagePNGRepresentation(self.iTunesUpload.artworkImage);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *imageName = [NSString stringWithFormat:@"image_%d.png", arc4random() % 1000];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES];
        return [NSURL fileURLWithPath:filePath];
    } else {
        UIImage *image = [UIImage imageNamed:@"AlbumImagePlaceholder2"];
        NSData *pngData = UIImagePNGRepresentation(image);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"];
        [pngData writeToFile:filePath atomically:YES];
        return [NSURL fileURLWithPath:filePath];
        //return nil;
    }
}

- (void)uploadArtwork {
    NSLog(@"Uploading artwork.");
    NSURL *url = [self albumImageNSURL];
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
    self.spinner.center = self.artworkImageView.center;
    [self.view addSubview:self.spinner];
    [self trim];
    
    self.view.userInteractionEnabled = NO;
    [self.player pause];
    [self.playbackTimer invalidate];
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

    return yapBuilder;
}

- (BOOL) didViewUploadPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_UPLOAD_POPUP_KEY];
}

#pragma mark - Upload Popup
- (void) showUploadPopup {
    self.uploadPopupVC = [[UploadPopupViewController alloc] initWithNibName:@"UploadPopupViewController" bundle:nil];
    [self presentPopupViewController:self.uploadPopupVC animationType:MJPopupViewAnimationFade];
}

@end
