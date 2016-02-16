//
//  YSYapsCollectionViewDataSource.h
//  YapTap
//
//  Created by Rudd Taylor on 12/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StreamingKit/STKAudioPlayer.h>

@class YSYapsCollectionViewDataSource, TrackCollectionViewCell;

@protocol YSYapsCollectionViewDelegate <NSObject>

- (void)yapsCollectionDataSource:(YSYapsCollectionViewDataSource *)dataSource didTapYapAtIndexPath:(NSIndexPath *)indexPath;
- (void)yapsCollectionDataSource:(YSYapsCollectionViewDataSource *)dataSource didTapSpotifyAtIndexPath:(NSIndexPath *)indexPath;
- (void)yapsCollectionDataSource:(YSYapsCollectionViewDataSource *)dataSource reloadCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface YSYapsCollectionViewDataSource : NSObject<UICollectionViewDataSource>

@property (weak) id<YSYapsCollectionViewDelegate> delegate;
@property (strong, nonatomic) NSArray* yaps;

- (void)updateCell:(TrackCollectionViewCell *)cell withState:(STKAudioPlayerState)state;

@end
