//
//  AddTextViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "AddTextViewController.h"
#import "ContactsViewController.h"
#import "YSAudioSourceController.h"
#import "JEProgressView.h"

@interface AddTextViewController ()
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet JEProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *addTextToYapButton;
@property (strong, nonatomic) IBOutlet UILabel *sendYapLabel;
@property (weak, nonatomic) IBOutlet YSColorPicker *colorPicker;


- (IBAction)didTapAddTextButton;

@end

@implementation AddTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.progressView.progress = self.yapBuilder.duration/10;
    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];
    
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textField.delegate = self;
    self.colorPicker.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;
        self.yapBuilder.text = self.textField.text;
        self.yapBuilder.color = self.view.backgroundColor;
        vc.yapBuilder = self.yapBuilder;
    }
}
- (IBAction)didTapNextButton:(UIButton *)sender {
    [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
}
- (IBAction)didTapBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)didTapAddTextButton {
    [self.textField becomeFirstResponder];
    self.textField.hidden = NO;
    self.sendYapLabel.hidden = YES;
    self.addTextToYapButton.hidden = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    //Remove extra space at end of string
    self.textField.text = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (self.textField.text.length == 0) {
        self.textField.hidden = YES;
        self.sendYapLabel.hidden = NO;
        self.addTextToYapButton.hidden = NO;
    }
    
    return YES;
}

#pragma mark - YSColorPickerDelegate

- (void)colorPicker:(YSColorPicker *)picker didSelectColor:(UIColor *)color
{
    self.view.backgroundColor = color;
}


@end
