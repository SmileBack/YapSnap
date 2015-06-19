//
//  YTSpotifyCategory.m
//  YapTap
//
//  Created by Dan B on 6/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTSpotifyCategory.h"

@implementation YTSpotifyCategory

- (id)initWithDisplayName:(NSString*)displayName spotifyURL:(NSString*)spotifiyURL {
    if (self = [super init]) {
        self.displayName = displayName;
        self.spotifyURL = [NSURL URLWithString:spotifiyURL];
    }
    return self;
}

+ (NSArray*)defaultCategories {
    return @[[[YTSpotifyCategory alloc] initWithDisplayName:@"Pop"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/5FJXhjdILmRA2z5bvz4nzf/tracks"],
             [[YTSpotifyCategory alloc] initWithDisplayName:@"Rock"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/4dJHrPYVdKgaCE3Lxrv1MZ/tracks"],
             [[YTSpotifyCategory alloc] initWithDisplayName:@"Rap"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/3jtuOxsrTRAWvPPLvlW1VR/tracks"],
             [[YTSpotifyCategory alloc] initWithDisplayName:@"Top"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/06KmJWiQhL0XiV6QQAHsmw/tracks"],
             [[YTSpotifyCategory alloc] initWithDisplayName:@"Hits"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/76h0bH2KJhiBuLZqfvPp3K/tracks"],
             [[YTSpotifyCategory alloc] initWithDisplayName:@"EDM"
                                                 spotifyURL:@"https://api.spotify.com/v1/users/spotify/playlists/76h0bH2KJhiBuLZqfvPp3K/tracks"],
             ];
}

@end
