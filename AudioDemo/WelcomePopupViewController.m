//
//  MJDetailViewController.m
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "WelcomePopupViewController.h"

@implementation WelcomePopupViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat borderWidth = 2.0f;
    
    if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
        self.view.frame = CGRectMake(0,0,270,260);
    } else if (IS_IPHONE_6_SIZE) {
        self.view.frame = CGRectMake(0,0,300,265);
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.view.frame = CGRectMake(0,0,340,265);
    }
    self.view.layer.borderColor = [UIColor whiteColor].CGColor;
    self.view.layer.borderWidth = borderWidth;
    
    self.dismissPopupButton.layer.cornerRadius = 10;
    self.dismissPopupButton.layer.borderWidth = 1;
    self.dismissPopupButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

@end
