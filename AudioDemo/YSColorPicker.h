//
//  YSColorPicker.h
//  Pods
//
//  Created by Dan B on 1/23/15.
//
//

#import <UIKit/UIKit.h>

@protocol YSColorPickerDelegate;

@interface YSColorPicker : UIView

@property (weak) id<YSColorPickerDelegate> delegate;

@end


@protocol YSColorPickerDelegate <NSObject>

- (void)colorPicker:(YSColorPicker*)picker didSelectColor:(UIColor*)color;

@end