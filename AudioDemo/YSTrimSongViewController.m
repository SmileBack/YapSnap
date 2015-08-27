//
//  YSTrimSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSTrimSongViewController.h"

#define CONFIRM_SEGUE @"Confirm Segue"

@interface YSTrimSongViewController ()

@end

@implementation YSTrimSongViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

#pragma mark - Actions
- (IBAction)didPressNext:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:CONFIRM_SEGUE sender:nil];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:CONFIRM_SEGUE]) {
        
    }
}

@end
