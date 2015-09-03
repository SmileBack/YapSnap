//
//  YSiTunesUpload.h
//  YapTap
//
//  Created by Jon Deokule on 8/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSITunesTrack.h"

// This stores additional information used when uploading the track.
// The extra fields aren't sent by the backend when retrieving these
// tracks later.
@interface YSiTunesUpload : YSITunesTrack
@property (nonatomic, strong) UIImage *artworkImage;
@property (nonatomic) NSTimeInterval trackDuration;

// Seconds into the track to start the clip
@property (nonatomic) float startTime;
@property (nonatomic) float endTime;

@property (nonatomic, strong) NSURL *trackURL;

@end
