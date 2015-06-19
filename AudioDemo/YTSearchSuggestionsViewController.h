//
//  YTSearchSuggestionsViewController.h
//  YapTap
//
//  Created by Dan B on 6/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTSpotifyCategory.h"

@protocol YTSearchSuggestionsViewControllerDelegate <NSObject>

- (void)didSelectSearchSuggestion:(YTSpotifyCategory *)suggestion;

@end

@interface YTSearchSuggestionsViewController : UIViewController

@property (nonatomic, weak) id<YTSearchSuggestionsViewControllerDelegate> searchSuggestionsDelegate;

@end
