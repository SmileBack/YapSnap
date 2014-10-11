//
//  LandingPageViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "LandingPageViewController.h"
#import "RecordVoiceViewController.h"

@interface LandingPageViewController ()

@end

@implementation LandingPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // if we're already authenticated, go right to the recording page
    if ([Global retrieveValueForKey:@"session_token"] != nil){
        RecordVoiceViewController* rvvc = [self.storyboard instantiateViewControllerWithIdentifier:@"RecordVoiceViewController"];
        //RecordVoiceViewController* rvvc = [[RecordVoiceViewController alloc] init];
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
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    //[super viewWillDisappear:animated];
}

- (IBAction) didTapEnterButton
{
    [self performSegueWithIdentifier:@"EnterNameViewControllerSegue" sender:self];
}

@end
