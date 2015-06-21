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

@class ContactsViewController;

@protocol ContactsViewControllerDelegate <NSObject>
- (void)updateYapBuilderContacts:(NSArray*)contacts;
@end

@interface ContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) YTBuilder *builder;
@property (nonatomic, weak) id <ContactsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *selectedContacts;

- (IBAction)didTapContinueButton;

@end
