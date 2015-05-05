//
//  UserCell.h
//  YapSnap
//
//  Created by Jon Deokule on 2/11/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *doubleTapLabel;

@property (strong, nonatomic) IBOutlet UILabel *friendOneLabel;
@property (strong, nonatomic) IBOutlet UILabel *friendTwoLabel;
@property (strong, nonatomic) IBOutlet UILabel *friendThreeLabel;

@property (strong, nonatomic) IBOutlet UIImageView *friendOneImage;
@property (strong, nonatomic) IBOutlet UIImageView *friendTwoImage;
@property (strong, nonatomic) IBOutlet UIImageView *friendThreeImage;

- (void) clearLabels;

@end
