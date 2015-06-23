//
//  YSTrack.h
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSTrack : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *spotifyID;
@property (nonatomic, strong) NSString *previewURL;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *spotifyURL;
@property (nonatomic, strong) NSNumber *secondsToFastForward;
@property (nonatomic) BOOL songVersionButtonsAreShowing;
@property (nonatomic) BOOL isExplainerTrack;

+ (NSArray *) tracksFromDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory;
+ (YSTrack *) trackFromDictionary:(NSDictionary *)trackDictionary;


@end
