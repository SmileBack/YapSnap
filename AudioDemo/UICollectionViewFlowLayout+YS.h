//
//  UICollectionViewFlowLayout+YS.h
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionViewFlowLayout (YS)

+ (UICollectionViewFlowLayout *)screenWidthLayoutWithHeightOffset:(CGFloat)offset;
+ (UICollectionViewFlowLayout *)screenWidthLayout;
+ (UICollectionViewFlowLayout *)appLayout;

@end
