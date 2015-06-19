//
//  YTSearchSuggestionsViewController.m
//  YapTap
//
//  Created by Dan B on 6/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTSearchSuggestionsViewController.h"
#import "YTRoundButton.h"

@interface YTSearchSuggestionsViewController ()

@property (strong, nonatomic) NSArray* categories;
@property (strong, nonatomic) NSMutableArray* buttons;

@end

@implementation YTSearchSuggestionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.categories = [YTSpotifyCategory defaultCategories];
    self.buttons = [NSMutableArray arrayWithCapacity:self.categories.count];
    
    // Constraints
    for (YTSpotifyCategory* category in self.categories) {
        YTRoundButton* view = [[YTRoundButton alloc] initWithText:category.displayName];
        [self.buttons addObject:view];
        [self.view addSubview:view];
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:0.25
                                                               constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:0.25
                                                               constant:0]];
        [view addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
        view.userInteractionEnabled = YES;
    }
    self.view.userInteractionEnabled = YES;
    
    // Top row
    for (int i = 0; i < self.buttons.count/2; i++) {
        UIView* button = self.buttons[i];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[button]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"button": button}]];
    }
    // Bottom row
    for (int i = 3; i < self.buttons.count; i++) {
        UIView* topRowButton = self.buttons[0];
        UIView* button = self.buttons[i];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topRow]-(10)-[button]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"button": button,
                                                                                    @"topRow": topRowButton}]];
    }
    
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[b1]-[b2]-[b3]-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"b1": self.buttons[0],
                                                                                @"b2": self.buttons[1],
                                                                                @"b3": self.buttons[2]}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[b4]-[b5]-[b6]-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"b4": self.buttons[3],
                                                                                @"b5": self.buttons[4],
                                                                                @"b6": self.buttons[5]}]];
}

#pragma mark - Actions

- (void)didTapButton:(UIButton*)button {
    NSUInteger selectedIndex = [self.buttons indexOfObject:button];
    if ([self.searchSuggestionsDelegate respondsToSelector:@selector(didSelectSearchSuggestion:)]) {
        [self.searchSuggestionsDelegate didSelectSearchSuggestion:self.categories[selectedIndex]];
    }
}

@end
