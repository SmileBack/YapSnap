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
//@property (weak, nonatomic) IBOutlet UIButton *addTextButton;
//@property (strong, nonatomic) IBOutlet UITextField *textForYapBox;
//@property (weak, nonatomic) IBOutlet UIImageView *pictureForYap;


//- (IBAction)didTapAddTextButton;

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
    
//    self.textForYapBox.autocapitalizationType = UITextAutocapitalizationTypeSentences; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
//    [self.textForYapBox addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged]; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
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

- (void) setupSendYapInterface
{
    self.microphone.hidden = YES;
//    self.addTextButton.hidden = NO;
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

    return YES;
}

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];

    if (elapsedTime > CAPTURE_THRESHOLD) {
        [self setupSendYapInterface];
    } else {
        [self resetUI];
    }
}

- (void) resetUI
{
    self.microphone.hidden = NO;
   // self.addTextButton.hidden = YES;
    
   // self.textForYapBox.hidden = YES; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
   // self.textForYapBox.text = @""; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
   // self.pictureForYap.hidden = YES; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
   // self.pictureForYap.image = nil; // TODO: REMOVE AFTER RE-WRITING SEND YAP PAGE
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


/*
#pragma mark - TextForYap Stuff
- (void) didTapAddTextButton {
    self.textForYapBox.hidden = NO;
    self.addTextButton.hidden = YES;
    [self.textForYapBox becomeFirstResponder];
    
    self.textForYapBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textForYapBox.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    
    if ([[self.textForYapBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        self.textForYapBox.hidden = YES;
        self.addTextButton.hidden = NO;
    } else {
        //Remove extra space at end of string
        self.textForYapBox.text = [self.textForYapBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        self.addTextButton.hidden = YES;
    }
    
    return YES;
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    NSLog( @"text changed: %@", self.textForYapBox.text);
    if ([self.textForYapBox.text isEqual: @"Flashback"]) {
        NSLog( @"Hoorayyyy");
        
        self.pictureForYap.hidden = NO;
        self.textForYapBox.hidden = YES;
        self.textForYapBox.text = @"";
        
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
    self.addTextButton.hidden = NO;
}
*/

@end
