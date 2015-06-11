//
//  YSMicSourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSMicSourceController.h"
#import <AudioToolbox/AudioToolbox.h> // IS THIS NECESSARY HERE? Added this for short sound feature. If not necessary, remove framework
#import "EZAudio.h"
#import "UIViewController+MJPopupViewController.h"
#import "RecordPopupViewController.h"

#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define DID_SEE_RECORD_POPUP_KEY @"yaptap.DidSeeRecordPopupKey7"
#define DISMISS_RECORD_POPUP @"DismissRecordPopup"

@interface YSMicSourceController ()<EZMicrophoneDelegate>
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) EZMicrophone* microphone;
@property (nonatomic, strong) EZRecorder* recorder;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sinusWaveTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sinusWaveWidthConstraint;
@property (strong, nonatomic) RecordPopupViewController *recordPopupVC;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;


@end

@implementation YSMicSourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Megaphone Page"];

    [self setupRecorder];
    [self setupNotifications];
    [self setSinusWaveViewProperties];
    [self setSinusWaveConstraints];
    
    if (!self.didSeeRecordPopup) {
        [self showRecordPopup];
    }
    
    [self.recordButton setImage:[UIImage imageNamed:@"RecordButtonBlueBorder10Pressed.png"] forState:UIControlStateHighlighted];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.sinusWaveView.alpha = 0;
    self.titleLabel.hidden = NO;
}

- (void) setSinusWaveConstraints {
    if (IS_IPHONE_4_SIZE ) {
        self.sinusWaveTopConstraint.constant = 70;
    } else if (IS_IPHONE_5_SIZE) {
        // Nothing necessary here
    } else if (IS_IPHONE_6_SIZE) {
        self.sinusWaveTopConstraint.constant = 135;
        self.sinusWaveWidthConstraint.constant = 165;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.sinusWaveTopConstraint.constant = 140;
        self.sinusWaveWidthConstraint.constant = 180;
    }
}

- (void) setSinusWaveViewProperties {
    // Sinus wave view
    self.sinusWaveView.plotType        = EZPlotTypeBuffer;
    self.sinusWaveView.shouldFill      = NO;
    self.sinusWaveView.shouldMirror    = YES;
    self.sinusWaveView.backgroundColor = THEME_BACKGROUND_COLOR;
    self.sinusWaveView.color           = [UIColor whiteColor];
    self.sinusWaveView.plotType        = EZPlotTypeBuffer;
    self.sinusWaveView.maxAmplitude = 10.0/10.0;
    //self.sinusWaveView.idleAmplitude = 1.5;
    self.sinusWaveView.waveWidth = 1;
    self.sinusWaveView.density = 1;
    //self.sinusWaveView.phaseShift = 2;
    //self.sinusWaveView.phase = 10;
    //self.sinusWaveView.frequency = 0.8;
    //self.sinusWaveView.waves = 4;
    
    self.sinusWaveView.alpha = 0;
    //self.navigationItem.titleView = self.sinusWaveView;
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserverForName:UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [UIView animateWithDuration:.1
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseOut
                                         animations:^{
                                             // TODO: Show text view here
                                             self.sinusWaveView.alpha = 0;
                                         }
                                         completion:nil];
                    }];
    
    [center addObserverForName:DISMISS_RECORD_POPUP
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Dismiss Welcome Popup");
                        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                    }];
}

- (YapBuilder *) getYapBuilder
{
    YapBuilder *builder = [YapBuilder new];
    
    builder.messageType = MESSAGE_TYPE_VOICE;
    
    return builder;
}

#pragma mark - Recorder Stuff
- (void) setupRecorder
{
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
}

#pragma mark - EZMicrophoneDelegate

-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    dispatch_async(dispatch_get_main_queue(),^{
        [self.sinusWaveView updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
}

- (IBAction)didTapRecord:(id)sender {
    [self startAudioCapture];
    self.titleLabel.hidden = YES;
}
- (IBAction)didUntapRecord:(id)sender {
    [self stopAudioCapture];
}

#pragma mark - Public API Methods
- (BOOL) startAudioCapture
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerDidStartAudioCapture:)]) {
                [self.audioCaptureDelegate audioSourceControllerDidStartAudioCapture:self];
            }
            
            NSLog(@"Microphone permission granted");
            // Stop the audio player before recording
            if (self.player.playing) {
                [self.player stop];
            }
            
            NSArray *pathComponents = [NSArray arrayWithObjects:
                                       [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                       @"MyAudioMemo.m4a",
                                       nil];
            NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
            
            if (!self.recorder) {
                NSLog(@"CREATE RECORDER");
                self.recorder = [EZRecorder recorderWithDestinationURL:outputFileURL
                                                          sourceFormat:self.microphone.audioStreamBasicDescription
                                                   destinationFileType:EZRecorderFileTypeM4A];
            }
            
            [self.microphone startFetchingAudio];
            
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];

            // TODO: Hide text label here
            self.sinusWaveView.alpha = 1;
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Recorded Voice"];
            [mixpanel.people increment:@"Recorded Voice #" by:[NSNumber numberWithInt:1]];
        }
        else {
            NSLog(@"Microphone permission denied");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mic Permission Disabled"
                                                            message:@"You disabled mic permission. To send a voice yap, go to your phone's Settings, click Privacy, and enable Microphone."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
    }];
    
    return YES;
}

- (void) stopAudioCapture
{
    if (self.recorder) {
        [self.microphone stopFetchingAudio];
        NSLog(@"DESTROY RECORDER");
        [self.recorder closeAudioFile];
        self.recorder = nil;
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerdidFinishAudioCapture:)]) {
            [self.audioCaptureDelegate audioSourceControllerdidFinishAudioCapture:self];
        }
    }
}

- (void) resetUI
{
    // Nothing for now.
}

#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.player stop];
    [self.player prepareToPlay];
}

#pragma mark - Onboarding Popup
- (void) showRecordPopup {
    double delay = .2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.recordPopupVC = [[RecordPopupViewController alloc] initWithNibName:@"RecordPopupViewController" bundle:nil];
        [self presentPopupViewController:self.recordPopupVC animationType:MJPopupViewAnimationFade];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_SEE_RECORD_POPUP_KEY];
    });
}

- (BOOL) didSeeRecordPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SEE_RECORD_POPUP_KEY];
}

@end
