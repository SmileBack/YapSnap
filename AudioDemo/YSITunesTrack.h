//
//  YSITunesTrack.h
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//

#import <Foundation/Foundation.h>

@interface YSITunesTrack : NSObject

@property (nonatomic, strong) NSString *iTunesTrackID;

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *songName;
@property (nonatomic, strong) NSNumber *persistentID;
@property (nonatomic, strong) NSString * albumName;
@property (nonatomic, strong) NSString * genreName;

@property (nonatomic, strong) NSString *awsSongUrl;
@property (nonatomic, strong) NSString *awsSongEtag;
@property (nonatomic, strong) NSString *awsAlbumImageUrl;
@property (nonatomic, strong) NSString *awsAlbumImageEtag;

+ (NSArray *) tracksFromArrayOfDictionaries:(NSArray *)array;
+ (YSITunesTrack *) trackFromDictionary:(NSDictionary *)trackDict;

@end
