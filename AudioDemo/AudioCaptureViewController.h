//
//  AudioCaptureViewController.h
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "YSAudioSourceController.h"
#import "YSRecordProgressView.h"
#import "PhoneContact.h"
#import "OffsetImageButton.h"

@interface AudioCaptureViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic) YSContact *contactReplyingTo;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *recordProgressView;


- (IBAction)recordTapped:(id)sender;

- (void)switchToSpotifyMode;
- (void)switchToMicMode;

- (BOOL)isInRecordMode;

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to;

@end
