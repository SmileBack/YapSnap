//
//  YSSegmentedControl.m
//  VRKL
//
//  Created by Rudd Taylor on 11/19/13.
//  Copyright (c) 2013 Varkala Inc. All rights reserved.
//

#import "YSSegmentedControl.h"
#import <Masonry.h>

NSUInteger const YSSegmentedControl_ViewTagOffset = 200;

@implementation YSSegmentedControlItem

+ (YSSegmentedControlItem *)itemWithTitle:(NSString *)title {
    YSSegmentedControlItem *item = [[YSSegmentedControlItem alloc] init];
    item.title = title;
    return item;
}

+ (YSSegmentedControlItem *)itemWithImage:(UIImage *)image {
    YSSegmentedControlItem *item = [[YSSegmentedControlItem alloc] init];
    item.image = image;
    return item;
}

@end

@interface YSSegmentedControl ()

@property (strong) UIView *underline;
@property (strong) UIView *triangle;
@property (weak) UIView *currentlyEnabledView;
@property UIColor *unhighlightedColor;

@end

@implementation YSSegmentedControl

@synthesize items = _items, isInactive = _isInactive;
@dynamic showsSelectionTriangle;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonSetup];
    }
    return self;
}

- (void)awakeFromNib {
    [self commonSetup];
}

- (void)commonSetup {
    UIView *topSeparator = UIView.new;
    UIView *bottomSeparator = UIView.new;
    UIView *left = UIView.new;
    UIView *right = UIView.new;
    
    self.unhighlightedColor = [UIColor colorWithRed:31/255.0 green:65/255.0 blue:102/255.0 alpha:1.0];
    self.backgroundColor = THEME_BACKGROUND_COLOR;
    
    for (UIView *view in @[ topSeparator, bottomSeparator, left, right ]) {
        [self addSubview:view];
        view.backgroundColor = UIColor.clearColor;
    }
    
    [bottomSeparator makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottom);
        make.width.equalTo(self.width);
        make.height.equalTo(@0.5);
        make.left.equalTo(self.left);
    }];
    [topSeparator makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.top);
        make.width.equalTo(self.width);
        make.height.equalTo(@0.5);
        make.left.equalTo(self.left);
    }];
    [left makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.left);
        make.top.equalTo(self.top);
        make.width.equalTo(@0.5);
        make.bottom.equalTo(self.bottom);
    }];
    [right makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.right);
        make.top.equalTo(self.top);
        make.width.equalTo(@0.5);
        make.bottom.equalTo(self.bottom);
    }];
    
    self.underline = [[UIView alloc] initWithFrame:CGRectZero];
    self.underline.backgroundColor = UIColor.whiteColor;
    [self addSubview:self.underline];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tap];
}

- (void)didTap:(UITapGestureRecognizer *)tap {
    NSInteger newSegmentIndex = [tap locationInView:self].x / (CGRectGetWidth(self.frame) / self.items.count);
    [self setEnabled:YES forSegmentAtIndex:newSegmentIndex animated:YES];
}

#pragma mark - Getters/Setters

- (void)setItems:(NSArray *)items {
    _items = items;
    UIView *previous = nil;
    for (NSUInteger i = 0; i < items.count; i++) {
        UIView *view = nil;
        YSSegmentedControlItem *item = items[i];
        if (item.image) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:item.image];
            imageView.contentMode = UIViewContentModeCenter;
            
            view = imageView;
        } else {
            UILabel *label = UILabel.new;
            label.text = item.title;
            label.font = [UIFont fontWithName:@"Futura-Medium" size:15];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = self.unhighlightedColor;
            view = label;
        }
        
        view.tag = i + YSSegmentedControl_ViewTagOffset;
        [self addSubview:view];
        [view makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.width).multipliedBy(1.0/items.count);
            make.height.equalTo(self.height).offset(-17);
            make.centerY.equalTo(self.centerY);
            make.left.equalTo(previous ? previous.right : self.left);
        }];
        
        if (item != items.lastObject) {
            UIView *separator = UIView.new;
            separator.backgroundColor = [UIColor clearColor];
            [self addSubview:separator];
            [separator makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.top);
                make.bottom.equalTo(self.bottom);
                make.left.equalTo(view.right);
                make.width.equalTo(@0.5);
            }];
        }
        previous = view;
    }
    if (items.count > 0) {
        [self setEnabled:YES forSegmentAtIndex:0 animated:NO];
    }
}

- (NSArray *)items {
    return _items;
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment {
    [self setEnabled:enabled forSegmentAtIndex:segment animated:NO];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated {
    if (segment != self.selectedSegmentIndex || self.isInactive) {
        self.isInactive = NO;
        UIView *oldView = self.currentlyEnabledView;
        
        if ([oldView isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)oldView;
            label.textColor = self.unhighlightedColor;
        }
        
        self.currentlyEnabledView = [self viewWithTag:YSSegmentedControl_ViewTagOffset + segment];
        CGSize selectedItemSize = CGSizeZero;
        YSSegmentedControlItem *selectedSegmentItem = (YSSegmentedControlItem *)self.items[self.selectedSegmentIndex];
        if (selectedSegmentItem.title) {
            UILabel *label = (UILabel *)self.currentlyEnabledView;
            label.textColor = UIColor.whiteColor;
            selectedItemSize = [selectedSegmentItem.title sizeWithAttributes:@{NSFontAttributeName : label.font}];
        } else {
            selectedItemSize = ((UIImageView *)self.currentlyEnabledView).image.size;
        }
        
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        
        [self.triangle remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bottom).offset(-0.5);
            make.centerX.equalTo(self.currentlyEnabledView.centerX);
        }];
        
        [self.underline remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.currentlyEnabledView.centerX);
            make.width.equalTo(@(selectedItemSize.width));
            make.bottom.equalTo(self.bottom).offset(-3);
            make.height.equalTo(@2.0f);
        }];
        
        if (animated) {
            [UIView animateWithDuration:0.3
                             animations:^(void) {
                                 [self layoutIfNeeded];
                             }];
        }
    }
}

- (BOOL)isInactive {
    return _isInactive;
}

- (void)setIsInactive:(BOOL)isInactive {
    if (isInactive != _isInactive) {
        _isInactive = isInactive;
        [UIView animateWithDuration:0.2
                         animations:^{
                             if (isInactive) {
                                 UIView *oldView = self.currentlyEnabledView;
                                 if ([oldView isKindOfClass:[UILabel class]]) {
                                     UILabel *label = (UILabel *)oldView;
                                     label.textColor = self.unhighlightedColor;
                                 }
                                 self.underline.alpha = 0.0;
                             } else {
                                 UIView *oldView = self.currentlyEnabledView;
                                 if ([oldView isKindOfClass:[UILabel class]]) {
                                     UILabel *label = (UILabel *)oldView;
                                     label.textColor = UIColor.whiteColor;
                                 }
                                 self.underline.alpha = 1.0;
                             }
                         }];
    }    
}

- (NSInteger)selectedSegmentIndex {
    return self.currentlyEnabledView.tag - YSSegmentedControl_ViewTagOffset;
}

- (void)setShowsSelectionTriangle:(BOOL)showsSelectionTriangle {
    if (showsSelectionTriangle && !self.triangle) {
        self.triangle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"down-white-arrow"]];
        [self addSubview:self.triangle];
        [self.triangle makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bottom).offset(-0.5);
            make.centerX.equalTo(self.currentlyEnabledView.centerX);
        }];
    } else {
        [self.triangle removeFromSuperview];
        self.triangle = nil;
    }
}

- (BOOL)showsSelectionTriangle {
    return self.triangle != nil;
}

@end

@implementation YSSegmentedControlScrollView

- (void)setControl:(YSSegmentedControl *)control {
    [_control removeTarget:self action:@selector(didChangeControl) forControlEvents:UIControlEventValueChanged];
    _control = control;
    [_control addTarget:self action:@selector(didChangeControl) forControlEvents:UIControlEventValueChanged];
}

- (void)didChangeControl {
    CGRect frame = self.control.currentlyEnabledView.frame;
    CGFloat offset = 100;
    frame.size.width = frame.size.width + offset;
    frame.origin.x = frame.origin.x - (offset/2);
    [self scrollRectToVisible:frame animated:YES];
}

@end
