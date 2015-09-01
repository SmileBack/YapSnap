//
//  YSSongTrimmer.h
//  YapTap
//
//  Created by Jon Deokule on 8/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSiTunesUpload.h"

typedef void (^TrimmedSongCallback)(NSString *url, NSError *error);


@interface YSSongTrimmer : NSObject

+ (YSSongTrimmer *) songTrimmerWithSong:(YSiTunesUpload *)upload;

- (void) trim:(TrimmedSongCallback)callback;

@end
