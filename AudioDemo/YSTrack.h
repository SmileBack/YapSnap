//
//  YSTrack.h
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSITunesTrack.h"

@interface YSTrack : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *spotifyID;
@property (nonatomic, strong) NSString *previewURL;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *albumImageURL;
@property (nonatomic, strong) NSString *spotifyURL;
@property (nonatomic, strong) NSString *genreName;
@property (nonatomic, strong) NSNumber *secondsToFastForward;
@property (readonly) BOOL isFromSpotify;

+ (NSArray *) tracksFromSpotifyDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory;
//+ (YSTrack *) trackFromSpotifyDictionary:(NSDictionary *)trackDictionary;
+ (NSArray *) tracksFromYapTapDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory;

+ (YSTrack *) trackFromYapTapDictionary:(NSDictionary *)trackDictionary;

+ (YSTrack *) trackFromiTunesTrack:(YSITunesTrack *)track;

@end
