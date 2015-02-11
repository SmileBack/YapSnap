//
//  FriendsViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 2/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "FriendsViewController.h"
#import "API.h"

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // TODO make users call
    [[API sharedAPI] friends:^(NSArray *friends, NSError *error) {
        NSLog(@"Friends: %@", friends);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
