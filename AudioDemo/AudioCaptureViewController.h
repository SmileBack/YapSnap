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

@interface AudioCaptureViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *arrowButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (weak, nonatomic) IBOutlet JEProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *explanation;

- (IBAction)recordTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)cancelTapped:(id)sender;
- (IBAction)didTapArrowButton;


@end
