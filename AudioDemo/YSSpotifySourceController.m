//
//  YSSpotifySourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSSpotifySourceController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import "SpotifyAPI.h"
#import "SpotifyTrackView.h"
#import "OpenInSpotifyAlertView.h"
#import <AVFoundation/AVAudioSession.h>

#define NO_SONGS_TO_PLAY_ALERT @"NoSongs"

@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIImageView *musicIcon;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic, strong) NSString *alertViewString;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupSearchBox];
    
    if ([self internetIsNotReachable]) {
        NSLog(@"Internet is not reachable");
    } else {
        NSLog(@"Internet is reachable");
    }
    
    UITapGestureRecognizer *tappedMusicIconImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMusicIconImage)];
    tappedMusicIconImage.numberOfTapsRequired = 1;
    [self.musicIcon addGestureRecognizer:tappedMusicIconImage];
}
 
- (void)tappedMusicIconImage {
    NSLog(@"Tapped Music Icon Image");
    if (self.searchBox.isFirstResponder) {
        NSLog(@"Search Box Is First Responder");
        [self.view endEditing:YES];
    } else {
        NSLog(@"Search Box Is Not First Responder");
        [self.searchBox becomeFirstResponder];
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) showNoInternetAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                    message:@"Please connect to the internet and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (YapBuilder *) getYapBuilder
{
    YapBuilder *builder = [YapBuilder new];
    
    builder.messageType = MESSAGE_TYPE_SPOTIFY;
    builder.track = self.songs[self.carousel.currentItemIndex];
    
    
    return builder;
}

#pragma mark - Search box stuff
- (void) setupSearchBox
{
    double delay = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.searchBox becomeFirstResponder];
    });
    
    self.searchBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    [self.searchBox setTintColor:[UIColor whiteColor]];
    self.searchBox.font = [UIFont fontWithName:@"Futura-Medium" size:30];
    self.searchBox.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([self.searchBox.text length] == 0) {
        NSLog(@"Searched Empty String");
        [self.view endEditing:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Send a Song"
                                                        message:@"To send a song, type the name of an artist, song, or album above."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        [self search:self.searchBox.text];
        [self.view endEditing:YES];
        
        //Remove extra space at end of string
        self.searchBox.text = [self.searchBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        //Background text color
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.searchBox.text];
        [attributedString addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.15] range:NSMakeRange(0, textField.text.length)];
        textField.attributedText = attributedString;
    }
    
    return YES;
}

- (void) search:(NSString *)search
{
    self.songs = nil;
    [self.carousel reloadData];
    self.musicIcon.hidden = YES;
    [self.loadingIndicator startAnimating];
    
    __weak YSSpotifySourceController *weakSelf = self;
    [[SpotifyAPI sharedApi] searchSongs:search withCallback:^(NSArray *songs, NSError *error) {
        if (songs) {
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            if (songs.count == 0) {
                [self.loadingIndicator stopAnimating];
                self.musicIcon.hidden = NO;

                NSLog(@"No Songs Returned For Search Query");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                message:@"We didn't find any songs for you. Try searching for something else."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [alert show];
                self.musicIcon.hidden = NO;
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
            }
        } else if (error) {
            [self.loadingIndicator stopAnimating];
            self.musicIcon.hidden = NO;
            
            if ([self internetIsNotReachable]) {
                [self showNoInternetAlert];
            } else {
                NSLog(@"Error Returning Songs %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                message:@"There was an error. Please try again in a bit."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [alert show];
            }
        }
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"Textfield did begin editing");
    self.carousel.scrollEnabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"Textfield did end editing");
    self.carousel.scrollEnabled = YES;
}

#pragma mark - iCarousel Stuff
#pragma mark iCarousel
- (NSInteger) numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.songs.count;
}

- (UIView *) carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    YSTrack *track = self.songs[index];
    SpotifyTrackView *trackView;

    if (view && [view isKindOfClass:[SpotifyTrackView class]]) {
        trackView = (SpotifyTrackView *) view;
    } else {
        CGRect frame = CGRectMake(0, 0, 200, 200);
        trackView = [[SpotifyTrackView alloc] initWithFrame:frame];

        trackView.imageView = [[UIImageView alloc] initWithFrame:frame];
        [trackView addSubview:trackView.imageView];

        trackView.label = [[UILabel alloc]initWithFrame:
                          CGRectMake(0, 200, 200, 25)];
        [trackView addSubview:trackView.label];
        
        trackView.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.spotifyButton.frame = CGRectMake(160, 5, 35, 35);
        [trackView.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
        [trackView addSubview:trackView.spotifyButton];
    }

    if (track.imageURL) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
    } else {
        trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
    }
    [trackView.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.05]];

    // Needed so the Spotify button can work
    trackView.spotifySongID = track.spotifyID;
    trackView.spotifyURL = track.spotifyURL;
    
    trackView.label.textColor = [UIColor whiteColor];
    trackView.label.backgroundColor = [UIColor clearColor];
    trackView.label.text = track.name;
    trackView.label.textAlignment = NSTextAlignmentCenter;
    trackView.label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    
    [trackView.spotifyButton addTarget:self action:@selector(confirmOpenInSpotify:) forControlEvents:UIControlEventTouchUpInside];

    return trackView;
}

- (void) confirmOpenInSpotify:(UIButton *)button
{
    if([self.searchBox isFirstResponder])
    {
        NSLog(@"Search box is in focus");
        [self.view endEditing:YES];
    }
    else
    {
        NSLog(@"Search box not in focus");
        UIView *parent = button.superview;
        if ([parent isKindOfClass:[SpotifyTrackView class]]) {
            SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
            YSTrack *selectedTrack = nil;
            for (YSTrack *track in self.songs) {
                if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                    selectedTrack = track;
                    break;
                }
            }
            OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithTrack:selectedTrack];
            [alert show];
        }
    }
}


- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
//    YSTrack *song = self.songs[index];
    if([self.searchBox isFirstResponder])
    {
        NSLog(@"Search box is in focus");
        [self.view endEditing:YES];
    }
    else
    {
        NSLog(@"Search box not in focus");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Press Red Button"
                                                        message:@"Hold the button below to listen to and send this song."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            return 1.1;
        }
        default:
        {
            return value;
        }
    }
}

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.player stop];
    [self enableUserInteraction];
}

- (void) enableUserInteraction
{
    [self.carousel setUserInteractionEnabled:YES];
    self.searchBox.enabled = YES;
}

#pragma mark - STKAudioPlayerDelegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didStartPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didFinishBufferingSourceWithQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStateReady) {
        NSLog(@"state == STKAudioPlayerStateReady");
    }
    
    if (state == STKAudioPlayerStateRunning) {
        NSLog(@"state == STKAudioPlayerStateRunning");
    }
    
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:self];
    }
    
    if (state == STKAudioPlayerStateBuffering) {
        NSLog(@"state == STKAudioPlayerStateBuffering");
    }
    
    if (state == STKAudioPlayerStatePaused) {
        NSLog(@"state == STKAudioPlayerStatePaused");
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"state == STKAudioPlayerStateStopped");
        [[NSNotificationCenter defaultCenter] postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION object:nil];
    }
    
    if (state == STKAudioPlayerStateError) {
        NSLog(@"state == STKAudioPlayerStateError");
    }
    
    if (state == STKAudioPlayerStateDisposed) {
        NSLog(@"state == STKAudioPlayerStateDisposed");
    }
    
    if (state == STKAudioPlayerStateBuffering && previousState == STKAudioPlayerStatePlaying) {
        NSLog(@"state changed from playing to buffering");
        [self enableUserInteraction];
        [audioPlayer stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_LOST_CONNECTION_NOTIFICATION object:nil];
    }
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"audioPlayer didFinishPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [self enableUserInteraction];
    [audioPlayer stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_UNEXPECTED_ERROR_NOTIFICATION object:nil];
}

#pragma mark - Implement public audio methods
- (BOOL) startAudioCapture
{
    if ([self internetIsNotReachable]){
        [self showNoInternetAlert];
        return NO;
    } else if (self.songs.count == 0) {
        NSLog(@"Can't Play Because No Song");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Send a Song"
                                                        message:@"To send a song, type the name of an artist, song, or album above."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        self.alertViewString = NO_SONGS_TO_PLAY_ALERT;
        [alert show];
        return NO;
    } else {
        //Disable User Interactions
        [self.carousel setUserInteractionEnabled:NO];
        self.searchBox.enabled = NO;
        
        YSTrack *song = self.songs[self.carousel.currentItemIndex];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        if ([song.previewURL isEqual: [NSNull null]]) {
            NSLog(@"URL is Null");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Song Not Available"
                                                            message:@"Unfortunately this song is not currently available."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [self enableUserInteraction];
            //THE FOLLOWING LINES STOP THE LOADING SPINNER
            double delay = 0.2;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION object:nil];
            });
        } else {
            [self.player play:song.previewURL];
        }
        return YES;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([NO_SONGS_TO_PLAY_ALERT isEqualToString:self.alertViewString]) {
        double delay = 0.4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.searchBox becomeFirstResponder];
        });
    }
}

@end
