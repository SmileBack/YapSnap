//
//  TrackView.h
//  YapTap
//
//  Created by Rudd Taylor on 9/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *songNameLabel;
@property (nonatomic, strong) UIButton *artistButton;
@property (nonatomic, strong) UIButton *albumImageButton;
@property (nonatomic) BOOL isBlurred;

@end
