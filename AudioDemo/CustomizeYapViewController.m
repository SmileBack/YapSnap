//
//  AddTextViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "CustomizeYapViewController.h"
#import "ContactsViewController.h"
#import "YSAudioSourceController.h"
#import "PhoneContact.h"
#import "UIViewController+Alerts.h"
#import "ContactManager.h"
#import "YSRecordProgressView.h"
#import "NextButton.h"
#import "YapsViewController.h"
#import <STKAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import "FriendsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface CustomizeYapViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *progressView;
//@property (weak, nonatomic) IBOutlet YSColorPicker *colorPicker;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *yapPhoto;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) STKAudioPlayer* player;
@property (strong, nonatomic) IBOutlet UIButton *resetPhotoButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) IBOutlet NextButton *continueButton;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *addRecipientsButton;

- (IBAction)didTapCameraButton;
- (IBAction)didTapResetPhotoButton;
- (IBAction)didTapAddRecipientsInDoubleTapToReplyFlow;

#define VIEWED_TEXT_ALERT_KEY @"yaptap.ViewedTextAlertKey"

@end

@implementation CustomizeYapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Customize Page"];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.progressView.progress = self.yapBuilder.duration/12;
    
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textView.delegate = self;
    self.textView.textContainer.maximumNumberOfLines = 5;
    self.textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    
    if (self.yapBuilder.contacts.count > 0) {
        [self updateBannerLabel];
    } else {
        if (self.isForwardingYap) {
            self.contactLabel.text = @"Select Recipients";
            if (self.yapBuilder.imageAwsUrl && ![self.yapBuilder.imageAwsUrl isEqual: [NSNull null]]) {
                self.resetPhotoButton.hidden = NO;
                self.albumImage.hidden = YES;
            }
        } else {
            self.contactLabel.text = @"Send Yap";
        }
    }
    
    double delay = 0.2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.continueButton startToPulsate];
    });
    
    [self.textView setTintColor:[UIColor whiteColor]];
    
    double delay2 = 0.2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.player = [STKAudioPlayer new];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    });
    
    if (IS_IPHONE_4_SIZE) {
        self.bottomConstraint.constant = 0;
        self.textView.font = [UIFont fontWithName:@"Futura-Medium" size:32];
    }
    
    [self.albumImage sd_setImageWithURL:[NSURL URLWithString:self.yapBuilder.track.imageURL]];
    self.textView.text = self.yapBuilder.text;
    if (self.yapBuilder.imageAwsUrl && ![self.yapBuilder.imageAwsUrl isEqual: [NSNull null]]) {
        [self.yapPhoto sd_setImageWithURL:[NSURL URLWithString:self.yapBuilder.imageAwsUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            self.yapPhoto.hidden = NO;
        }];
    }

    if (!self.isForwardingYap) {
        if (self.isReplying) {
            double delay3 = 1.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.textView becomeFirstResponder];
            });
        } else {
            double delay3 = .8;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.textView becomeFirstResponder];
            });
        }
    }
    
    [self addShadowToTextView];
    
    if (self.isForwardingYap) {
        self.titleLabel.text = @"Edit Yap & Forward";
    } else if (self.isReplying) {
        PhoneContact *contact = self.yapBuilder.contacts.firstObject;
        NSString *contactFirstName = [[contact.name componentsSeparatedByString:@" "] objectAtIndex:0];
        if ([contact.phoneNumber isEqualToString:@"+13245678910"] || [contact.phoneNumber isEqualToString:@"+13027865701"]) {
            self.titleLabel.text = @"Reply to YapTap Team";
        } else {
            self.titleLabel.text = [NSString stringWithFormat:@"Reply to %@", contactFirstName];
        }
    } else {
        self.titleLabel.text = @"Add Message";
    }
    
    self.resetPhotoButton.layer.cornerRadius = 4;
    self.resetPhotoButton.layer.borderWidth = 1;
    self.resetPhotoButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    
    //self.yapPhoto.layer.cornerRadius = 4;
    self.yapPhoto.layer.borderWidth = 1;
    self.yapPhoto.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    self.yapPhoto.clipsToBounds = YES;
    
    self.progressView.trackTintColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    
    if (self.yapBuilder.contacts.count > 0) {
        self.addRecipientsButton.hidden = NO;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.continueButton.userInteractionEnabled = YES; //This is here just in case
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
    [self.player stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateBannerLabel {
    PhoneContact *contact = self.yapBuilder.contacts.firstObject;
    if (self.yapBuilder.contacts.count > 1) {
        self.contactLabel.text = [NSString stringWithFormat:@"%lu Recipients", (unsigned long)self.yapBuilder.contacts.count];
    } else {
        if (IS_IPHONE_4_SIZE) {
            self.contactLabel.text = [NSString stringWithFormat:@"To: %@", contact.name];
        } else {
            self.contactLabel.text = [NSString stringWithFormat:@"Send to\n%@", contact.name];
        }
    }
    self.contactLabel.numberOfLines = 2;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;
        vc.builder = self.yapBuilder;
    }   else if ([@"Contacts Segue No Animation" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;
        vc.builder = self.yapBuilder;
        vc.delegate = self;
    }   else if ([@"YapsViewControllerSegue" isEqualToString:segue.identifier]) {
        YapsViewController *vc = segue.destinationViewController;
        vc.pendingYaps = sender;
        vc.comingFromContactsOrCustomizeYapPage = YES;
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) sendYap
{
    if ([self internetIsNotReachable]) {
        self.continueButton.userInteractionEnabled = YES;
        [self showNoInternetAlert];
    } else {
        __weak CustomizeYapViewController *weakSelf = self;
        
        NSArray *pendingYaps =
        [[API sharedAPI] sendYapBuilder:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.yapBuilder.contacts];
                        } else {
                            double delay = 0.5;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                NSLog(@"Error: %@", error);
                                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Yap Didn't Send!"];
                            });
                        }
                    }];
        NSLog(@"Sent yaps call");
        
        [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:pendingYaps];
        
        self.continueButton.userInteractionEnabled = YES;
    }
}

- (IBAction)didTapNextButton:(UIButton *)sender
{
    self.continueButton.userInteractionEnabled = NO;
    self.yapBuilder.text = self.textView.text;
    self.yapBuilder.color = self.view.backgroundColor;
    
    if (self.yapBuilder.contacts.count > 0) {
        [self sendYap];
    } else {
        [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
        self.continueButton.userInteractionEnabled = YES;
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Continue On Customize Page"];
}

- (IBAction)didTapAddRecipientsInDoubleTapToReplyFlow {
    self.yapBuilder.text = self.textView.text;
    self.yapBuilder.color = self.view.backgroundColor;

    [self performSegueWithIdentifier:@"Contacts Segue No Animation" sender:nil];
}

- (IBAction)didTapCameraButton {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take a Photo", @"Upload a Photo", nil];
    actionSheet.tag = 100;
    [actionSheet showInView:self.view];
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Add Camera Button"];
}

- (BOOL) textView: (UITextView*) textView shouldChangeTextInRange: (NSRange) range replacementText: (NSString*) text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        
        self.textView.text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (!self.isForwardingYap && !self.isReplying) {
            if (self.textView.text.length == 0) {
                self.titleLabel.alpha = 1;
                self.titleLabel.text = @"Add Message";
            } else {
                [UIView animateWithDuration:.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.titleLabel.alpha = 0;
                                 }
                                 completion:nil];
            }
        }
        
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"Textfield did begin editing");
}

#pragma mark - YSColorPickerDelegate

- (void)colorPicker:(YSColorPicker *)picker didSelectColor:(UIColor *)color // Not currently in UI
{
    self.view.backgroundColor = color;
}

#pragma mark - Select/Take Photo

- (void) selectPhoto {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void) takePhoto
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)didTapResetPhotoButton {
    NSLog(@"Tapped Cancel Photo Button");
    
    self.yapPhoto.image = nil;
    self.yapBuilder.image = nil;
    self.resetPhotoButton.hidden = YES;
    self.yapPhoto.hidden = YES;
    self.albumImage.hidden = NO;
    
    self.yapBuilder.imageAwsEtag = nil;
    self.yapBuilder.imageAwsUrl = nil;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Reset Photo Button"];
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.yapPhoto.image = chosenImage;
    
    self.yapPhoto.hidden = NO;
    self.resetPhotoButton.hidden = NO;
    self.albumImage.hidden = YES;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Selected a Photo"];

    // create a local image that we can use to upload to s3
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.png"];
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    [imageData writeToFile:path atomically:YES];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.yapBuilder.image = url;

    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    if ((!self.didViewTextAlert) && ([self.textView.text length] == 0)) {
        double delay = .7;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showBlueNotificationText:@"Tap Photo To Add Text!"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_TEXT_ALERT_KEY];
        });
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Canceled Choosing Photo"];
}

#pragma mark - Spotify Alert Methods

- (BOOL) didViewTextAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_TEXT_ALERT_KEY];
}

- (void) addShadowToTextView
{
    self.textView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.textView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.textView.layer.shadowOpacity = 1.0f;
    self.textView.layer.shadowRadius = 1.0f;
}

#pragma mark - UIActionSheet method implementation

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Tapped Action Sheet; Button Index: %ld", (long)buttonIndex);
    // Take a photo
    if (actionSheet.tag == 100) {
        if (buttonIndex == 0) {
            [self takePhoto];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Take Photo"];
            
        // Upload a photo
        } else if (buttonIndex == 1) {
            [self selectPhoto];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Upload Photo"];
        
        } else if (buttonIndex == 2) {
            NSLog(@"Did tap cancel");
        }
    }
}

- (IBAction)leftButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - ContactsViewControllerDelegate

- (void) updateYapBuilderContacts:(NSArray *)contacts {
    if (contacts.count > 0) {
        self.yapBuilder.contacts = contacts;
        [self updateBannerLabel];
    }
    [self.view endEditing:YES];
}


@end
