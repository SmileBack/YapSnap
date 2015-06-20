//
//  YTSpotifyCategory.h
//  YapTap
//
//  Created by Dan B on 6/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTSpotifyCategory : NSObject

//@property (strong, nonatomic) NSString* displayName;
@property (strong, nonatomic) NSURL* spotifyURL;

//- (id)initWithDisplayName:(NSString*)displayName spotifyURL:(NSString*)spotifiyURL;

- (id)initWithSpotifyURL:(NSString*)spotifiyURL;

//+ (NSArray*)defaultCategories;

@end
