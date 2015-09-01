//
//  YSTrimSongViewController.h
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSiTunesUpload.h"

@interface YSTrimSongViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic, strong) YSiTunesUpload *iTunesUpload;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) IBOutlet UIImageView *artworkImageView;

@end
