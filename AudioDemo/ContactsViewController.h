//
//  ContactsViewController.h
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactSelectionCell.h"
#import "API.h"

@interface ContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) YTBuilder *builder;

- (IBAction)didTapContinueButton;

@end
