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
#import "ZLSinusWaveView.h"

@interface YSMicSourceController ()<EZMicrophoneDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *microphoneView;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) EZMicrophone* microphone;
@property (nonatomic, strong) EZRecorder* recorder;
@property (weak, nonatomic) IBOutlet ZLSinusWaveView *sinusWaveView;

@end

@implementation YSMicSourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Mic Page"];

    [self setupRecorder];
    
    UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMicrophoneImage)];
    tapped.numberOfTapsRequired = 1;
    [self.microphoneView addGestureRecognizer:tapped];
    
    // Sinus wave view
    
    self.sinusWaveView.plotType        = EZPlotTypeBuffer;
    self.sinusWaveView.shouldFill      = NO;
    self.sinusWaveView.shouldMirror    = YES;
    self.sinusWaveView.backgroundColor = THEME_BACKGROUND_COLOR;
    self.sinusWaveView.color           = [UIColor whiteColor];
    self.sinusWaveView.plotType        = EZPlotTypeBuffer;
    self.sinusWaveView.maxAmplitude = 3/10.0;
}

- (void)tappedMicrophoneImage {
    NSLog(@"Tapped Microphone Image");
    double delay = 0.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[YTNotifications sharedNotifications] showNotificationText:@"Hold Red Button"];
    });
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

#pragma mark - Public API Methods
- (BOOL) startAudioCapture
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
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
            
            self.recorder = [EZRecorder recorderWithDestinationURL:outputFileURL
                                                      sourceFormat:self.microphone.audioStreamBasicDescription
                                               destinationFileType:EZRecorderFileTypeM4A];
            [self.microphone startFetchingAudio];
            
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:self];
            
            self.microphoneView.image = [UIImage imageNamed:@"Microphone_Gray2.png"];
            
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

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.microphone stopFetchingAudio];
    [self.recorder closeAudioFile];
    self.recorder = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    self.microphoneView.image = [UIImage imageNamed:@"Microphone_White2.png"];
}

//- (void) startPlayback //Play button isn't in the UI currently
//{
//    if (!self.recorder.recording){
//        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
//        [self.player setDelegate:self];
//        
//        self.player.enableRate = YES;
//        self.player.rate = 2.0f;
//        
//        [self.player play];
//    }
//}

- (void) resetUI
{
    // Nothing for now.
}

#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.player stop];
    [self.player prepareToPlay];
}

@end
