//
//  YapCell.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YapCell.h"

@implementation YapCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    for (UIGestureRecognizer *gest in self.goToSpotifyView.gestureRecognizers) {
        [self.goToSpotifyView removeGestureRecognizer:gest];
    }
}

@end
