//
//  UIViewController+ScreenSize.m
//  YapSnap
//
//  Created by Jon Deokule on 2/22/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UIViewController+ScreenSize.h"

@implementation UIViewController (ScreenSize)

- (BOOL) isiPhone4Size
{
    return self.view.frame.size.height == 480;
}

@end
