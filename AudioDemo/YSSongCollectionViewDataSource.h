//
//  YSSongCollectionViewDataSource.h
//  YapTap
//
//  Created by Dan B on 8/14/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YSSongCollectionViewDataSource;

@protocol YSSongCollectionViewDelegate <NSObject>

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongAtIndexPath:(NSIndexPath *)indexPath;
- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapArtistAtIndexPath:(NSIndexPath *)indexPath;
- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongOptionOneAtIndexPath:(NSIndexPath *)indexPath;
- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongOptionTwoAtIndexPath:(NSIndexPath *)indexPath;
- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSpotifyAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface YSSongCollectionViewDataSource : NSObject<UICollectionViewDataSource>

@property (weak) id<YSSongCollectionViewDelegate> delegate;
@property (strong, nonatomic) NSArray* songs;

@end
