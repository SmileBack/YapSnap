//
//  YapBuilder.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YapBuilder.h"

@implementation YapBuilder

- (id) init
{
    self = [super init];
    if (self) {
        self.text = @"";
    }
    return self;
}

- (BuilderType) builderType
{
    return BuilderTypeYap;
}

@end
