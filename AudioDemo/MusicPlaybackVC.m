//
//  MusicPlaybackVC.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "MusicPlaybackVC.h"

@interface MusicPlaybackVC ()

@end

@implementation MusicPlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"Long Press: %@", self.longPress);
    [self.longPress addTarget:self action:@selector(pressed:)];
    
    [self.longPress addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"change: %@", change);
    NSLog(@"long press is: %@", self.longPress);
}

- (void) pressed:(UILongPressGestureRecognizer *)gest
{
    NSLog(@"PRESSED?");
}


@end
