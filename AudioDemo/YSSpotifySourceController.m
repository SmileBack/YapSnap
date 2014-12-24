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


@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIImageView *musicIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) STKAudioPlayer *player;
@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupSearchBox];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Search box stuff
- (void) setupSearchBox
{
    double delay = 2.0;
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search for a Song"
                                                        message:@"Type the name of an artist, song, or album."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        [self search:self.searchBox.text];
        [self.view endEditing:YES];
    }
    
    return YES;
}

- (void) search:(NSString *)search
{
    __weak YSSpotifySourceController *weakSelf = self;
    [[SpotifyAPI sharedApi] searchSongs:search withCallback:^(NSArray *songs, NSError *error) {
        if (songs) {
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            if (songs.count == 0) {
                NSLog(@"No Songs Returned For Search Query");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                message:@"We didn't find any songs for you. Try searching for something else."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [alert show];
            } else {
                NSLog(@"Returned Songs Successfully");
                self.musicIcon.hidden = YES;
            }
        } else if (error) {
            NSLog(@"Error Returning Songs %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"There was an error. Please try again in a bit."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
        }
    }];
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
        trackView.imageView.image = [UIImage imageNamed:@"Microphone_White2.png"];
    }

    // Needed so the Spotify button can work
    trackView.spotifySongID = track.spotifyID;
    trackView.spotifyURL = track.spotifyURL;
    
    trackView.label.textColor = [UIColor whiteColor];
    trackView.label.backgroundColor = [UIColor clearColor];
    trackView.label.text = track.name;
    trackView.label.textAlignment = NSTextAlignmentCenter;
    trackView.label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    
    [trackView.spotifyButton addTarget:self action:@selector(openInSpotify:) forControlEvents:UIControlEventTouchUpInside];

    return trackView;
}

- (void) openInSpotify:(UIButton *)button
{
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
        NSString *url = [NSString stringWithFormat:@"spotify://track/%@", trackView.spotifySongID];
        BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        if (!success) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:trackView.spotifyURL]];
        }
    }
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
//    YSTrack *song = self.songs[index];
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

- (void) setupSendSongInterface
{
    //self.titleLabel.hidden = NO;
    self.carousel.hidden = YES;
    self.musicIcon.hidden = YES;
    self.titleLabel.hidden = NO;
}

- (void) resetUI
{
    self.carousel.hidden = NO;
    self.titleLabel.hidden = YES;
}

#pragma mark - STKAudioPlayerDelegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:nil];
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [audioPlayer stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_ERROR_NOTIFICATION object:nil];
}


#pragma mark - Implement public audio methods
- (BOOL) startAudioCapture
{
    if (self.songs.count == 0) {
        NSLog(@"No Song To Play");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search for a Song"
                                                        message:@"To send a song, type the name of an artist, song, or album above."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        [NSException raise:@"NoSong" format:@"No songs"];
        // TODO - Progress Bar shouldn't start filling up
    } else {
        self.musicIcon.hidden = YES;
        YSTrack *song = self.songs[self.carousel.currentItemIndex];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [self.player play:song.previewURL];
    }
}

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.player stop];
    
    if (elapsedTime > CAPTURE_THRESHOLD) {
        [self setupSendSongInterface];
    } else {
        [self resetUI];
    }

// SEND YAP TO BACKEND - backend needs to be implemented
/*
 -    [[API sharedAPI] sendSong:song withCallback:^(BOOL success, NSError *error) {
 -        if (success) {
 -            NSLog(@"IT WORKED!!!!");
 -        } else {
 -            NSLog(@"it didnt work: %@", error);
 -        }
 -    }];
 */
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    double delay = 0.4;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.searchBox becomeFirstResponder];
    });
}

@end
