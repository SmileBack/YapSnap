//
//  ContactSelectionCell.h
//  NightOut
//
//  Created by Jon Deokule on 6/25/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactSelectionCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) IBOutlet UILabel *phoneLabel;
@property (strong, nonatomic) IBOutlet UIView *selectionView;
@property (strong, nonatomic) IBOutlet UIImageView *checkImageView;

@end
