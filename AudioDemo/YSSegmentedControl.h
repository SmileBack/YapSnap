//  YSSegmentedControl.h
//
//  Created by Rudd Taylor on 11/19/13.
//  Copyright (c) 2013 Varkala Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSUInteger const YSSegmentedControl_ViewTagOffset;

typedef NS_ENUM(NSInteger, YSSegmentedControlItemStyle) {
    YSSegmentedControlItemStylePlain = 0,
    YSSegmentedControlItemStyleRightDecorator = 1,
};

@interface YSSegmentedControlItem : NSObject

@property NSString* title;
@property UIImage* image;
@property YSSegmentedControlItemStyle style;

+ (YSSegmentedControlItem*)itemWithTitle:(NSString*)title;
+ (YSSegmentedControlItem*)itemWithImage:(UIImage*)image;
+ (YSSegmentedControlItem *)itemWithTitle:(NSString *)title style:(YSSegmentedControlItemStyle)style;

@end

@interface YSSegmentedControl : UIControl

@property (strong) NSArray* items;
@property(nonatomic) NSInteger selectedSegmentIndex;
@property BOOL showsSelectionTriangle;
@property BOOL isInactive;

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment;
- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated;

@end

@interface YSSegmentedControlScrollView: UIScrollView

@property (strong, nonatomic) YSSegmentedControl* control;

@end