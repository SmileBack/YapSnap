//
//  Builder.h
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    BuilderTypeYap,
    BuilderTypeAddFriends
} BuilderType;

@interface YTBuilder : NSObject

@property (nonatomic, readonly) BuilderType builderType;

@property (nonatomic, strong) NSArray *contacts;
@end
