//
//  MJDetailViewController.h
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DISMISS_CONTACTS_POPUP @"DismissContactsPopup"
#define SHOW_CONTACTS_POPUP @"ShowContactsPopup"

@interface ContactsPopupViewController : UIViewController

- (IBAction)didTapCancelButton;

@end
