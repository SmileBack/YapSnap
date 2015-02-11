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
#import "PhoneContact.h"
#import "UIViewController+Alerts.h"
#import "ContactManager.h"

@interface AddTextViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet JEProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *addTextToYapButton;
@property (strong, nonatomic) IBOutlet UILabel *sendYapLabel;
@property (weak, nonatomic) IBOutlet YSColorPicker *colorPicker;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *flashbackImageView;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet UIButton *continueButton;


- (IBAction)didTapAddTextButton;

@end

@implementation AddTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.progressView.progress = self.yapBuilder.duration/10;
    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];
    
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textView.delegate = self;
    self.colorPicker.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.textView];
    
    if (self.yapBuilder.contacts.count > 0) {
        PhoneContact *contact = self.yapBuilder.contacts.firstObject;
        self.contactLabel.text = [NSString stringWithFormat:@"Send yap to %@", contact.name];
    } else {
        self.contactLabel.text = @"";
    }
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
        self.yapBuilder.text = self.textView.text;
        self.yapBuilder.color = self.view.backgroundColor;
        vc.yapBuilder = self.yapBuilder;
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) sendYap
{
    self.continueButton.userInteractionEnabled = NO;
    
    if ([self internetIsNotReachable]) {
        [self showNoInternetAlert];
        self.continueButton.userInteractionEnabled = YES;
    } else {
        __weak AddTextViewController *weakSelf = self;
        
        [[API sharedAPI] sendYapBuilder:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.yapBuilder.contacts];
                            [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:self];
                        } else {
                            // uh oh spaghettios
                            // TODO: tell the user something went wrong
                            NSLog(@"Error: %@", error);
                            self.continueButton.userInteractionEnabled = YES;
                        }
                    }];
        NSLog(@"Sent yaps call");
    }

}

- (IBAction)didTapNextButton:(UIButton *)sender {
    if (self.yapBuilder.contacts.count > 0) {
        [self sendYap];
    } else {
        [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
    }
}
- (IBAction)didTapBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)didTapAddTextButton {
    [self.textView becomeFirstResponder];
    self.textView.hidden = NO;
    self.addTextToYapButton.hidden = YES;
}

- (BOOL) textView: (UITextView*) textView shouldChangeTextInRange: (NSRange) range replacementText: (NSString*) text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        
        self.textView.text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (self.textView.text.length == 0) {
            self.addTextToYapButton.hidden = NO;
            self.textView.hidden = YES;
        }
        
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(NSNotification *)notification {
   
    if ([self.textView.text isEqualToString:@"Flashback"] || [self.textView.text isEqualToString:@"flashback"] || [self.textView.text isEqualToString:@"Flashback "] || [self.textView.text isEqualToString:@"flashback "]) {
        [self selectPhoto];
    }
}

#pragma mark - YSColorPickerDelegate

- (void)colorPicker:(YSColorPicker *)picker didSelectColor:(UIColor *)color
{
    self.view.backgroundColor = color;
}

#pragma mark - Select Photo

- (void) selectPhoto {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.flashbackImageView.image = chosenImage;

    // create a local image that we can use to upload to s3
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.png"];
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    [imageData writeToFile:path atomically:YES];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.yapBuilder.image = url;

    self.textView.text = @"";
    self.textView.userInteractionEnabled = NO;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    self.textView.text = @"";
    self.textView.userInteractionEnabled = YES;
    [self.textView becomeFirstResponder];
}


@end
