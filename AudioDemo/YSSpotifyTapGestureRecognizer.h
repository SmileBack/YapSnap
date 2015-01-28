//
//  SpotifyTapGestureRecognizer.h
//  YapSnap
//
//  Created by Jon Deokule on 1/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSYap.h"

@interface YSSpotifyTapGestureRecognizer : UITapGestureRecognizer
@property (nonatomic, strong) YSYap *yap;
@end
