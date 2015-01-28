//
//  OpenInSpotifyAlertView.h
//  YapSnap
//
//  Created by Jon Deokule on 12/28/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIAlertView.h>
#import "YSTrack.h"
#import "YSYap.h"

@interface OpenInSpotifyAlertView : UIAlertView<UIAlertViewDelegate>

- (id) initWithTrack:(YSTrack *)track;
- (id) initWithYap:(YSYap *)yap;

@end
