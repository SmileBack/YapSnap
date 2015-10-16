//
//  YSGenreGroupViewController.m
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSGenreGroupViewController.h"
#import "YTTrackGroup.h"

@interface YSGenreGroupViewController ()

@end

@implementation YSGenreGroupViewController

- (NSArray *)trackGroups {
    return @[
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_hiphop_tracks"
                                    imageName:@"Genre_HipHop"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_film_tracks"
                                    imageName:@"Genre_Film2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_pop_tracks"
                                    imageName:@"Genre_Pop3"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_rock_tracks"
                                    imageName:@"Genre_Rock2"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_country_tracks"
                                    imageName:@"Genre_Country3"],
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_edm_tracks"
                                    imageName:@"Genre_EDM4"]
             
             /*
             [YTTrackGroup trackGroupWithName:@""
                                    apiString:@"genre_latin_tracks"
                                    imageName:@"Genre_Latin4"]
              */
             ];
}

@end
