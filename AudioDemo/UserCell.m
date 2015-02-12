//
//  UserCell.m
//  YapSnap
//
//  Created by Jon Deokule on 2/11/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UserCell.h"

@implementation UserCell

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self clearLabels];
    }
    return self;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self clearLabels];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self clearLabels];
    }
    return self;
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self clearLabels];
    }
    return self;
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    [self clearLabels];
}

- (void) clearLabels
{
    self.nameLabel.text = nil;
    
    self.friendOneLabel.text = nil;
    self.friendTwoLabel.text = nil;
    self.friendThreeLabel.text = nil;
}

@end
