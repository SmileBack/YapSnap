//
//  NextButton.m
//  YapTap
//
//  Created by Dan B on 3/16/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "NextButton.h"

@implementation NextButton

- (void)pulsate
{
    NSMutableArray* constraints = NSMutableArray.new;
    CGFloat originalDimension;
    for (NSLayoutConstraint* dimension in self.constraints)
    {
        if (dimension.firstItem == self &&
            (dimension.firstAttribute == NSLayoutAttributeWidth || dimension.firstAttribute == NSLayoutAttributeHeight)
            && dimension.constant == CGRectGetHeight(self.frame)) {
            [constraints addObject:dimension];
            originalDimension = dimension.constant;
        }
    }
    
    void (^changeSize)(CGFloat) = ^void(CGFloat height) {
        for (NSLayoutConstraint* dimension in constraints) {
            dimension.constant = height;
        }
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
    };
    
    CGFloat expandedDimension = originalDimension * 1.2;
    changeSize(expandedDimension);
    CGFloat const duration = 0.3;
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        changeSize(originalDimension);
        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            changeSize(expandedDimension);
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                changeSize(originalDimension);
                [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    [self layoutIfNeeded];
                } completion:nil];
            }];
        }];
    }];
}

@end
