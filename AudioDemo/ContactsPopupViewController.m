//
//  MJDetailViewController.m
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "ContactsPopupViewController.h"

@implementation ContactsPopupViewController


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
}

- (IBAction) didTapCancelButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:DISMISS_CONTACTS_POPUP object:nil];
}

@end
