//
//  LandingPageViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "LandingPageViewController.h"
#import "AudioCaptureViewController.h"
#import "YSUser.h"

@implementation LandingPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    YSUser *user = [YSUser currentUser];
    
    // if we're already authenticated, go right to the recording page
    if (user.hasSessionToken){
        AudioCaptureViewController* rvvc = [self.storyboard instantiateViewControllerWithIdentifier:@"AudioCaptureViewController"];
        [self.navigationController pushViewController:rvvc animated:NO];
    }else{
        // Do any additional setup after loading the view.
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
        self.view.backgroundColor = THEME_BACKGROUND_COLOR;
        
        self.enterButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:22];
        [self.enterButton setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction) didTapEnterButton
{
    [self performSegueWithIdentifier:@"EnterPhoneNumberViewControllerSegue" sender:self];
}

@end
