//
//  YSSpinnerView.m
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSSpinnerView.h"

@implementation YSSpinnerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.layer.cornerRadius = 10;
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:spinner];
        spinner.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidX(self.bounds));
        [spinner startAnimating];
    }
    return self;
}

@end
