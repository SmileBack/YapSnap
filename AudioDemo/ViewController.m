//
//  ViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "ViewController.h"
#import "ContactsViewController.h"

@interface ViewController () {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    NSTimer *timer;
    CGFloat progress;
}

@end

@implementation ViewController
@synthesize playButton, recordButton; //stopButton

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR; //[UIColor colorWithRed:245.0f/255.0f green:75.0f/255.0f blue:75.0f/255.0f alpha:1];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
	
    // Disable Stop/Play button when application launches
    //[stopButton setEnabled:NO];
    [playButton setEnabled:NO];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];

    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    
    self.arrowButton.hidden = YES;
    self.cancelButton.hidden = YES;
    
    self.progressView.progress = 0;
    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];

}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupProgress {
    // Reset everything and start moving the progressbar near its end of doom!
    progress = 0.0;
    [self.progressView setProgress:progress];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                             target:self
                                           selector:@selector(updateProgress)
                                           userInfo:nil
                                            repeats:YES];
}

- (void) updateProgress {
    
    progress += 0.001;
    
    NSLog(@"%f",progress);
    
    [self.progressView setProgress:progress];
    if(progress >= 1.0f) {
        
        //STOP RECORDING
        [recorder stop];
        [timer invalidate];
        [self setupSendYapInterface];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
    }
}

- (IBAction)recordTapped:(id)sender {
    
    [self setupProgress];
    
    // Stop the audio player before recording
    if (player.playing) {
        [player stop];
    }
    
    // Start recording
    [recorder record];
        
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
        
    self.titleLabel.hidden = YES;
    self.microphone.hidden = NO;
    self.explanation.hidden = YES;

    [playButton setEnabled:NO];
}

- (IBAction)recordUntapped:(id)sender {
    
    //STOP RECORDING
    [recorder stop];
    [timer invalidate];
    
    NSLog(@"Time elapsed: %f", self.progressView.progress);
    if(self.progressView.progress < 0.02) {
        self.progressView.progress = 0.0;

        self.titleLabel.hidden = NO;
        self.microphone.hidden = YES;
        self.explanation.hidden = NO;
    } else {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        
        [self setupSendYapInterface];
    }
}

- (void) setupSendYapInterface
{
    self.recordButton.hidden =YES;
    self.titleLabel.hidden = NO;
    self.titleLabel.text = @"Send Yap";
    self.microphone.hidden = YES;
    
    self.arrowButton.hidden = NO;
    self.cancelButton.hidden = NO;
}

- (IBAction)playTapped:(id)sender {
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player setDelegate:self];
        [player play];
    }
}

- (IBAction)cancelTapped:(id)sender {
    self.arrowButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.recordButton.hidden = NO;
    self.titleLabel.text = @"Record";
    self.progressView.progress = 0.0;
}

- (IBAction) didTapArrowButton
{
    [self performSegueWithIdentifier:@"ContactsViewControllerSegue" sender:self];
}

- (IBAction)arrowTapped:(id)sender {
}

#pragma mark - AVAudioRecorderDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    
    [playButton setEnabled:YES];    
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
}


@end
