//
//  YSMicSourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSAudioSourceController.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h> // IS THIS NECESSARY HERE? Added this for short sound feature
#import "ZLSinusWaveView.h"

@interface YSMicSourceController : YSAudioSourceController<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet ZLSinusWaveView *sinusWaveView;

@end
