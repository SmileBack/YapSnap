//
//  NSArray+Shuffle.h
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Shuffle)

- (void)shuffleArray;

@end

@interface NSArray (Shuffle)

- (NSArray *)shuffledArray;

@end
