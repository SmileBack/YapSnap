//
//  NSArray+Shuffle.m
//  YapTap
//
//  Created by Rudd Taylor on 8/27/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "NSArray+Shuffle.h"

@implementation NSMutableArray (Shuffle)

- (void)shuffleArray {
    for (NSUInteger i = 0; i < self.count; ++i) {
        NSInteger remainingCount = self.count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end

@implementation NSArray (Shuffle)

- (NSArray *)shuffledArray {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self];
    [array shuffleArray];
    return array;
}

@end
