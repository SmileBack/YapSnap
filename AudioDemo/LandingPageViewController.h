//
//  LandingPageViewController.h
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BButton.h"

@interface LandingPageViewController : UIViewController

@property (nonatomic, strong)  IBOutlet BButton *enterButton;

- (IBAction)didTapEnterButton;

@end
