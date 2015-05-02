//
//  SpotifyArtistFactory.h
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpotifyArtistFactory : NSObject

+ (NSArray *) artistsForGenre:(NSString *) genre;

@end
