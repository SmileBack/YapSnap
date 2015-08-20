//  YSSegmentedControl.h
//
//  Created by Rudd Taylor on 11/19/13.
//  Copyright (c) 2013 Varkala Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSUInteger const YSSegmentedControl_ViewTagOffset;

@interface YSSegmentedControlItem : NSObject

@property NSString* title;
@property UIImage* image;

+ (YSSegmentedControlItem*)itemWithTitle:(NSString*)title;
+ (YSSegmentedControlItem*)itemWithImage:(UIImage*)image;

@end

@interface YSSegmentedControl : UIControl

@property (strong) NSArray* items;
@property(nonatomic) NSInteger selectedSegmentIndex;
@property BOOL showsSelectionTriangle;

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment;
- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated;

@end