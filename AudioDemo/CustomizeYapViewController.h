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
#import "ContactsViewController.h"
#import <STKAudioPlayer.h>

@interface CustomizeYapViewController : UIViewController<YSColorPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate, ContactsViewControllerDelegate, STKAudioPlayerDelegate>

@property (nonatomic, strong) YapBuilder *yapBuilder;
@property (assign, nonatomic) BOOL isForwardingYap;
@property (assign, nonatomic) BOOL isReplyingWithText;

- (IBAction)leftButtonPressed:(id)sender;

@end
