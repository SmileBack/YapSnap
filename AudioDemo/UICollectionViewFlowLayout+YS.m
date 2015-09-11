//
//  UICollectionViewFlowLayout+YS.m
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UICollectionViewFlowLayout+YS.h"

@implementation UICollectionViewFlowLayout (YS)

+ (UICollectionViewFlowLayout *)appLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 2;
    flowLayout.minimumLineSpacing = 2;
    flowLayout.sectionInset = UIEdgeInsetsMake(2, 2, 2, 2);
    if (IS_IPHONE_6_PLUS_SIZE) {
        flowLayout.itemSize = CGSizeMake(204, 234);
    } else if (IS_IPHONE_6_SIZE) {
        flowLayout.itemSize = CGSizeMake(184, 220);
    } else {
        flowLayout.itemSize = CGSizeMake(157, 185);
    }
    return flowLayout;
}

@end
