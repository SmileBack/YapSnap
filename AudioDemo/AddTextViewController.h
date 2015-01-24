//
//  AddTextViewController.h
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YapBuilder.h"
#import "YSColorPicker.h"

@interface AddTextViewController : UIViewController<YSColorPickerDelegate>

@property (nonatomic, strong) YapBuilder *yapBuilder;

@end
