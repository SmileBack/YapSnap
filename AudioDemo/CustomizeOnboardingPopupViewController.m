//
//  MJDetailViewController.m
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "CustomizeOnboardingPopupViewController.h"

@implementation CustomizeOnboardingPopupViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat borderWidth = 1.0f;
    
    if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
        self.view.frame = CGRectMake(0,0,270,260);
    } else if (IS_IPHONE_6_SIZE) {
        self.view.frame = CGRectMake(0,0,300,260);
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.view.frame = CGRectMake(0,0,340,260);
    }
    self.view.layer.borderColor = [UIColor whiteColor].CGColor;
    self.view.layer.borderWidth = borderWidth;
    self.view.layer.cornerRadius = 5;
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
}

- (IBAction) didTapCancelButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:DISMISS_CUSTOMIZE_ONBOARDING_POPUP_NOTIFICATION object:nil];
}

@end
