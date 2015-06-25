//
//  YTTrackCategory.h
//  YapTap
//
//  Created by Dan B on 6/25/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTTrackGroup : NSObject

@property (nonatomic, strong) NSString *apiString;
@property (nonatomic, strong) NSString *categoryName;
@property (nonatomic, strong) NSArray *songs;

@end
