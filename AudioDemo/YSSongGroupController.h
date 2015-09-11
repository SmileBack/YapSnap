//
//  YSSongGroupController.h
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "AudioCaptureViewController.h"

@interface YSSongGroupController : YSAudioSourceViewController

@property (readonly) NSArray *trackGroups; // To be overridden by subclasses

@end
