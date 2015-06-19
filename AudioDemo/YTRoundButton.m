//
//  YTRoundTextButton.m
//  YapTap
//
//  Created by Dan B on 6/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTRoundButton.h"

@implementation YTRoundButton

- (id)initWithSubview:(UIView *)subview {
    if ((self = [UIButton buttonWithType:UIButtonTypeCustom])) {
        self.layer.borderColor = UIColor.whiteColor.CGColor;
        self.layer.borderWidth = 1;
        self.backgroundColor = THEME_DARK_BLUE_COLOR;
        
        [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:subview];
        
        // Constraints
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"view": subview}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:@{@"view": subview}]];
    }
    return self;
}

- (id)initWithText:(NSString*)text {
    UILabel* label = UILabel.new;
    if (self = [self initWithSubview:label]) {
        label.text = text;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = UIColor.whiteColor;
        label.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
    if (self = [self initWithSubview:imageView]) {
        // Configure image view if needed
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutIfNeeded];
    // Force roundness
    self.layer.cornerRadius = self.frame.size.width / 2;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backgroundColor = UIColor.grayColor;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backgroundColor = THEME_DARK_BLUE_COLOR;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backgroundColor = THEME_DARK_BLUE_COLOR;
}

@end
