//
//  UIViewController+Navigation.m
//  YapTap
//
//  Created by Jon Deokule on 3/18/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UIViewController+Navigation.h"
#import "AudioCaptureViewController.h"

@implementation UIViewController (Navigation)
- (BOOL) popToBaseAudioCaptureController:(BOOL)animated
{
    NSArray *vcs = self.navigationController.viewControllers;
    for (UIViewController *vc in vcs) {
        if ([vc isKindOfClass:[AudioCaptureViewController class]]) {
            if (!animated) {
                [self.navigationController popToViewController:vc animated:NO];
                AudioCaptureViewController *audioVC = (AudioCaptureViewController *)vc;
                [audioVC resetUI];
            } else {
                BOOL animate = [vcs indexOfObject:self] - 1 == [vcs indexOfObject:vc];
                if (!animate) {
                    AudioCaptureViewController *audioVC = (AudioCaptureViewController *)vc;
                    [audioVC resetUI];
                }
                [self.navigationController popToViewController:vc animated:animate];
            }
            return YES;
        }
    }
    return NO;
}
@end
