//
//  OpenInSpotifyAlertView.h
//  YapSnap
//
//  Created by Jon Deokule on 12/28/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIAlertView.h>
#import "YSTrack.h"

@interface OpenInSpotifyAlertView : UIAlertView<UIAlertViewDelegate>

@property (nonatomic, strong) YSTrack *track;

- (id) initWithTrack:(YSTrack *)track;
@end
