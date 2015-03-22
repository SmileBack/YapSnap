//
//  LandingPageViewController.h
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LandingPageViewController : UIViewController

@property (nonatomic, strong)  IBOutlet UIButton *logInButton;
@property (nonatomic, strong)  IBOutlet UIButton *signUpButton;
@property (nonatomic, strong)  IBOutlet UIImageView *imageView;

- (IBAction)didTapSignUpButton;
- (IBAction)didTapLogInButton;

@end
