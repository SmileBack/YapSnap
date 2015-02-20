//
//  AudioCaptureViewController.h
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JEProgressView.h"
#import "YSAudioSourceController.h"
#import "PhoneContact.h"

@interface AudioCaptureViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet JEProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *explanation;
@property (strong, nonatomic) IBOutlet UIButton *spotifyModeButton;
@property (strong, nonatomic) IBOutlet UIButton *micModeButton;
@property (nonatomic, strong) YSAudioSourceController *audioSource;

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;


- (IBAction)recordTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)didTapYapsPageButton;
- (BOOL)isInRecordMode;

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to;

@end
