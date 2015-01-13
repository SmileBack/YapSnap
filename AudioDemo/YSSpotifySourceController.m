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

#define NO_SONGS_TO_PLAY_ALERT @"NoSongs"

@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIImageView *musicIcon;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic, strong) NSString *alertViewString;
@property (weak, nonatomic) IBOutlet UIButton *addTextButton;
@property (strong, nonatomic) IBOutlet UITextField *textForYapBox;
@property (weak, nonatomic) IBOutlet UIImageView *pictureForYap;

- (IBAction)didTapAddTextButton;

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
    
    [self.textForYapBox addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged]; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
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
    
    // Tag == 1 refers to the textfield where user searches for song
   if (textField.tag == 1) {
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
    // Tag == 2 refers to the textfield where user adds text to yap
   } else if (textField.tag == 2) {
       [self.view endEditing:YES];
       
       if ([[self.textForYapBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
           self.textForYapBox.hidden = YES;
           self.addTextButton.hidden = NO;
       } else {
           //Remove extra space at end of string
           self.textForYapBox.text = [self.textForYapBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
           
           self.addTextButton.hidden = YES;
       }
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

- (void) setupSendSongInterface
{
    self.carousel.hidden = YES;
    self.searchBox.hidden = YES;
    self.musicIcon.hidden = YES;
    self.addTextButton.hidden = NO;
}

- (void) resetUI
{
    self.carousel.hidden = NO;
    [self.carousel setUserInteractionEnabled:YES];
    self.searchBox.enabled = YES;
    self.searchBox.hidden = NO;
    self.addTextButton.hidden = YES;
    
    self.textForYapBox.hidden = YES; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
    self.textForYapBox.text = @""; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
    self.pictureForYap.hidden = YES; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
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
        [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:nil];
    }
    
    if (state == STKAudioPlayerStateBuffering) {
        NSLog(@"state == STKAudioPlayerStateBuffering");
    }
    
    if (state == STKAudioPlayerStatePaused) {
        NSLog(@"state == STKAudioPlayerStatePaused");
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"state == STKAudioPlayerStateStopped");
        [[NSNotificationCenter defaultCenter] postNotificationName:STK_AUDIO_PLAYER_STOPPED_NOTIFICATION object:nil];
    }
    
    if (state == STKAudioPlayerStateError) {
        NSLog(@"state == STKAudioPlayerStateError");
    }
    
    if (state == STKAudioPlayerStateDisposed) {
        NSLog(@"state == STKAudioPlayerStateDisposed");
    }
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"audioPlayer didFinishPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [audioPlayer stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_ERROR_NOTIFICATION object:nil];
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
        self.musicIcon.hidden = YES;
        
        //Disable User Interactions
        [self.carousel setUserInteractionEnabled:NO];
        self.searchBox.enabled = NO;
        
        YSTrack *song = self.songs[self.carousel.currentItemIndex];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [self.player play:song.previewURL];
        return YES;
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
    if ([NO_SONGS_TO_PLAY_ALERT isEqualToString:self.alertViewString]) {
        double delay = 0.4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.searchBox becomeFirstResponder];
        });
    }
}

#pragma mark - TextForYap Stuff
- (void) didTapAddTextButton {
    self.textForYapBox.hidden = NO;
    self.addTextButton.hidden = YES;
    [self.textForYapBox becomeFirstResponder];
    
    self.textForYapBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textForYapBox.delegate = self;
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    NSLog( @"text changed: %@", self.textForYapBox.text);
    if ([self.textForYapBox.text isEqual: @"Flashback"]) {
        NSLog( @"Hoorayyyy");
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.pictureForYap.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
