//
//  YSMicSourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSMicSourceController.h"


@interface YSMicSourceController ()
@property (weak, nonatomic) IBOutlet UIImageView *microphone;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation YSMicSourceController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupRecorder];
    
    UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMicrophoneImage)];
    tapped.numberOfTapsRequired = 1;
    [self.microphone addGestureRecognizer:tapped];
    //REMOVE
    UITapGestureRecognizer *tappedView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView)];
    tappedView.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tappedView];
}
//REMOVE
- (void)tappedView {
    NSLog(@"Tapped View");
}

- (void)tappedMicrophoneImage {
    NSLog(@"Tapped Microphone Image");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Press Red Button"
                                                    message:@"Hold the button below to record and send your voice."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];

    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];

    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
}

#pragma mark - Public API Methods
- (BOOL) startAudioCapture
{
    // Stop the audio player before recording
    if (self.player.playing) {
        [self.player stop];
    }

    // Start recording
    [self.recorder record];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:nil];
    
    self.microphone.image = [UIImage imageNamed:@"Microphone_Gray2.png"];

    return YES;
}

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    self.microphone.image = [UIImage imageNamed:@"Microphone_White2.png"];
}

- (void) startPlayback
{
    if (!self.recorder.recording){
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
        [self.player setDelegate:self];
        [self.player play];
    }
}

#pragma mark - AVAudioRecorderDelegate
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_END_NOTIFICATION object:nil];
}

#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self.player stop];
    [self.player prepareToPlay];
}

@end
