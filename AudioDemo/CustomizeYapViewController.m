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
@property (nonatomic) CGFloat pitchShiftValue;
@property (strong, nonatomic) IBOutlet UIButton *resetPhotoButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *balloonLeftConstraint;

@property (strong, nonatomic) IBOutlet NextButton *continueButton;
@property (strong, nonatomic) IBOutlet UIButton *addTextToYapButton;
@property (strong, nonatomic) IBOutlet UIButton *balloonButton;
@property (strong, nonatomic) IBOutlet UIImageView *balloonButtonImage;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (strong, nonatomic) IBOutlet UIImageView *cameraButtonImage;
@property (nonatomic, strong) NSString *balloonCancelButtonTitle;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;

@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;



- (IBAction)didTapAddTextButton;
- (IBAction)didTapBalloonButton;
- (IBAction)didTapCameraButton;
- (IBAction)didTapResetPhotoButton;

#define VIEWED_SPOTIFY_ALERT_KEY @"yaptap.ViewedSpotifyAlert"

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
        PhoneContact *contact = self.yapBuilder.contacts.firstObject;
        if (IS_IPHONE_4_SIZE) {
            self.contactLabel.text = [NSString stringWithFormat:@"To: %@", contact.name];
        } else {
            self.contactLabel.text = [NSString stringWithFormat:@"Send to\n%@", contact.name];
        }
        self.contactLabel.numberOfLines = 2;
    } else {
        if (self.isForwardingYap) {
            self.contactLabel.text = @"Forward Yap";
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
    
    
    [self setBalloonLeftConstraint];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(didTapImageView)];
    [self.yapPhoto addGestureRecognizer:tapGesture];
    
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
        double delay3 = .8;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textView becomeFirstResponder];
        });
    }
    
    [self addShadowToTextView];
    
    if (self.isForwardingYap) {
        self.titleLabel.text = @"Edit Message";
    } else if (self.isReplying) {
        PhoneContact *contact = self.yapBuilder.contacts.firstObject;
        NSString *contactFirstName = [[contact.name componentsSeparatedByString:@" "] objectAtIndex:0];
        self.titleLabel.text = [NSString stringWithFormat:@"Reply to %@", contactFirstName];
    } else {
        self.titleLabel.text = @"Add Message";
    }
}

- (void) addEmbededCamera {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.view.frame = CGRectMake(0, 72, [UIScreen mainScreen].bounds.size.width - 2, [UIScreen mainScreen].bounds.size.width -2);
    
    imagePicker.showsCameraControls = NO;
    //imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    imagePicker.delegate = self;
    
    [self addChildViewController:imagePicker];
    [self.view addSubview:imagePicker.view];
    [imagePicker didMoveToParentViewController:self];
    
    self.imagePicker = imagePicker;
}

- (void) setBalloonLeftConstraint {
    if ([self.yapBuilder.messageType isEqual: @"VoiceMessage"]) {
        //self.balloonButton.hidden = NO;
        //self.balloonButtonImage.hidden = NO;
        if (IS_IPHONE_4_SIZE) {
            // Nothing necessary here
        } else if (IS_IPHONE_5_SIZE) {
            // Nothing necessary here
        } else if (IS_IPHONE_6_SIZE) {
            self.balloonLeftConstraint.constant = 78;
        } else if (IS_IPHONE_6_PLUS_SIZE ) {
            self.balloonLeftConstraint.constant = 94;
        }
        
    } else if ([self.yapBuilder.messageType isEqual: @"SpotifyMessage"]) {
        if (IS_IPHONE_4_SIZE) {
            self.balloonLeftConstraint.constant = 16;
        } else if (IS_IPHONE_5_SIZE) {
            self.balloonLeftConstraint.constant = 16;
        } else if (IS_IPHONE_6_SIZE) {
            self.balloonLeftConstraint.constant = 43;
        } else if (IS_IPHONE_6_PLUS_SIZE ) {
            self.balloonLeftConstraint.constant = 59;
        }
    }
}

- (void) styleCustomizationButtons {
    self.balloonButton.layer.cornerRadius = 26;
    self.balloonButton.layer.borderWidth = 2;
    self.balloonButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.addTextToYapButton.layer.cornerRadius = 26;
    self.addTextToYapButton.layer.borderWidth = 2;
    self.addTextToYapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.cameraButton.layer.cornerRadius = 26;
    self.cameraButton.layer.borderWidth = 2;
    self.cameraButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void) didTapBalloonButton
{
    if (self.pitchShiftValue == 0) {
        self.balloonCancelButtonTitle = @"Cancel";
    } else {
        self.balloonCancelButtonTitle = @"Back to Normal";
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a Voice Filter"
                                                             delegate:self
                                                    cancelButtonTitle:self.balloonCancelButtonTitle
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Helium", @"Chipmunk", @"Darth Vader", nil];
    actionSheet.tag = 200;
    [actionSheet showInView:self.view];
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    
    [self reduceAlphaOfButtons];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Balloon"];
}

- (void) playAudioWithPitch:(CGFloat)pitch {
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    self.player.pitchShift = pitch;
    [self.player playURL:outputFileURL];
}

- (void) resetProgressViewColor {
    if (IS_IPHONE_5_SIZE) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRedNew.png"]];
    } else if (IS_IPHONE_4_SIZE) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRedNew.png"]];
    } else {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRedNew.png"]];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;
        vc.builder = self.yapBuilder;
    } else if ([@"YapsViewControllerSegue" isEqualToString:segue.identifier]) {
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
        
        NSArray *vcs = self.navigationController.viewControllers;
        BOOL isFriendsFlow = vcs && vcs.count > 1 && [vcs[0] isKindOfClass:[FriendsViewController class]];
        
        NSArray *pendingYaps =
        [[API sharedAPI] sendYapBuilder:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.yapBuilder.contacts];
                            double delay = 0.5;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if (isFriendsFlow) {
                                    [[YTNotifications sharedNotifications] showNotificationText:@"Yap sent!"];
                                }
                            });
                        } else {
                            double delay = 0.5;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                NSLog(@"Error: %@", error);
                                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Yap Didn't Send!"];
                            });
                        }
                    }];
        NSLog(@"Sent yaps call");
        
        if (isFriendsFlow) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FRIENDS_YAP_SENT_NOTIFICATION object:nil];
        } else {
            [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:pendingYaps];
        }
        self.continueButton.userInteractionEnabled = YES;
    }
}

- (IBAction)didTapNextButton:(UIButton *)sender
{
    self.continueButton.userInteractionEnabled = NO;
    self.yapBuilder.text = self.textView.text;
    self.yapBuilder.color = self.view.backgroundColor;
    // To get pitch value in 'cent' units, multiply self.pitchShiftValue by STK_PITCHSHIFT_TRANSFORM
    self.yapBuilder.pitchValueInCentUnits = [NSNumber numberWithFloat:(1000*self.pitchShiftValue)];
    
    if (self.yapBuilder.contacts.count > 0) {
        [self sendYap];
    } else {
        [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
        self.continueButton.userInteractionEnabled = YES;
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Continue On Customize Page"];
}
- (IBAction)didTapBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)didTapAddTextButton {
    

}

- (IBAction)didTapCameraButton {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take a Photo", @"Photo Library", nil];
    actionSheet.tag = 100;
    [actionSheet showInView:self.view];
    
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
    
    [self reduceAlphaOfButtons];
    
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
                [self updateAlphaOfButtons];
                self.titleLabel.text = @"Add Message";
            } else {
                self.titleLabel.text = @"";
            }
        }
        
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"Textfield did begin editing");
    [self reduceAlphaOfButtons];
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
    [self removeShadowFromTextView];
    [self updateAlphaOfButtons];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Reset Photo Button"];
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.yapPhoto.image = chosenImage;
    
    self.yapPhoto.hidden = NO;
    self.resetPhotoButton.hidden = NO;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Selected a Photo"];

    // create a local image that we can use to upload to s3
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.png"];
    NSData *imageData = UIImagePNGRepresentation(chosenImage);
    [imageData writeToFile:path atomically:YES];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    self.yapBuilder.image = url;

    //self.textView.userInteractionEnabled = NO;
    [self addShadowToTextView];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    [self updateAlphaOfButtons];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Canceled Choosing Photo"];
}

#pragma mark - Spotify Alert Methods

- (void) viewedSpotifyAlert
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_SPOTIFY_ALERT_KEY];
}

- (BOOL) didViewSpotifyAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_SPOTIFY_ALERT_KEY];
}

- (void) didTapImageView
{
    [self.resetPhotoButton setImage:[UIImage imageNamed:@"ResetButtonLarger.png"] forState:UIControlStateNormal];
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.resetPhotoButton setImage:[UIImage imageNamed:@"ResetButton3.png"] forState:UIControlStateNormal];
    });
}

- (void) addShadowToTextView
{
    self.textView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.textView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.textView.layer.shadowOpacity = 1.0f;
    self.textView.layer.shadowRadius = 1.0f;
}

- (void) removeShadowFromTextView
{
    /*
    self.textView.layer.shadowColor = [[UIColor clearColor] CGColor];
    self.textView.layer.shadowOffset = CGSizeMake(0, 0);
    self.textView.layer.shadowOpacity = 0;
    self.textView.layer.shadowRadius = 0;
     */
}

- (void) updateAlphaOfButtons {
    if ((self.textView.text.length > 0) || self.yapPhoto.image != nil) {
        [self reduceAlphaOfButtons];
    } else {
        [self restoreAlphaOfButtons];
    }
    
}

- (void) reduceAlphaOfButtons {
    /*
    self.cameraButton.alpha = 0.3;
    self.addTextToYapButton.alpha = 0.3;
    self.balloonButton.alpha = 0.3;
    self.balloonButtonImage.alpha = 0.3;
    self.cameraButtonImage.alpha = 0.3;
     */
}

- (void) restoreAlphaOfButtons {
    /*
    self.cameraButton.alpha = 1;
    self.addTextToYapButton.alpha = 1;
    self.balloonButton.alpha = 1;
    self.balloonButtonImage.alpha = 1;
    self.cameraButtonImage.alpha = 1;
    self.resetPhotoButton.alpha = 1;
     */
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
            [self updateAlphaOfButtons];
        }
    } else if (actionSheet.tag == 200) {
        if (buttonIndex == 0) {
            if (self.isiPhone5Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone5.png"]];
            } else if (self.isiPhone4Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone4.png"]];
            } else {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellow.png"]];
            }
            
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            if (volume < 0.5) {
                double delay = .2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showPitchVolumeText:@"Playing Helium Voice..." andSubtitleText:@"Turn up the volume"];
                });
            } else {            
                double delay = .1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showBlueNotificationText:@"Playing Helium Voice..."];
                });
            }
            
            self.pitchShiftValue = 1.0; // +1000
            [self playAudioWithPitch:self.pitchShiftValue];
            
            self.balloonButton.layer.borderColor = HELIUM_PITCH_COLOR.CGColor;
            self.balloonButton.layer.borderWidth = 3;
            [self.balloonButtonImage setImage:[UIImage imageNamed:@"Balloon20.png"]];
            
            [self updateAlphaOfButtons];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Pitch Helium"];
        } else if (buttonIndex == 1) {
            if (self.isiPhone5Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone5.png"]];
            } else if (self.isiPhone4Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone4.png"]];
            } else {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreen.png"]];
            }
            
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            if (volume < 0.5) {
                double delay = .1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showPitchVolumeText:@"Playing Chipmunk Voice..." andSubtitleText:@"Turn up the volume"];
                });
            } else {
                double delay = .1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showBlueNotificationText:@"Playing Chipmunk Voice..."];
                });
            }
            
            self.pitchShiftValue = 0.5; // +500
            [self playAudioWithPitch:self.pitchShiftValue];
            
            self.balloonButton.layer.borderColor = CHIPMUNK_PITCH_COLOR.CGColor;
            self.balloonButton.layer.borderWidth = 3;
            [self.balloonButtonImage setImage:[UIImage imageNamed:@"Chipmunk80.png"]];
            
            [self updateAlphaOfButtons];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Pitch Chipmunk"];
        } else if (buttonIndex == 2) {
            if (self.isiPhone5Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone5.png"]];
            } else if (self.isiPhone4Size) {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone4.png"]];
            } else {
                [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlue.png"]];
            }
            
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            if (volume < 0.5) {
                double delay = .1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showPitchVolumeText:@"Playing Darth Vader Voice..." andSubtitleText:@"Turn up the volume"];
                });
            } else {
                double delay = .1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showBlueNotificationText:@"Playing Darth Vader Voice..."];
                });
            }
            
            self.pitchShiftValue = -0.4; // -400
            [self playAudioWithPitch:self.pitchShiftValue];
            
            self.balloonButton.layer.borderColor = DARTH_VADER_PITCH_COLOR.CGColor;
            self.balloonButton.layer.borderWidth = 3;
            [self.balloonButtonImage setImage:[UIImage imageNamed:@"DarthVader10.png"]];
            
            [self updateAlphaOfButtons];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Pitch Darth Vader"];
        } else if (buttonIndex == 3) {
            NSLog(@"Did tap cancel");
            
            self.balloonButton.layer.borderColor = [UIColor whiteColor].CGColor;
            self.balloonButton.layer.borderWidth = 2;
            
            [self updateAlphaOfButtons];
            
            if (self.pitchShiftValue != 0) {
                [[YTNotifications sharedNotifications] showBlueNotificationText:@"Back to Normal"];
                [self resetProgressViewColor];
                [self.balloonButtonImage setImage:[UIImage imageNamed:@"Balloon20.png"]];
                self.player.pitchShift = 0;
                self.pitchShiftValue = 0;
                [self.player stop];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Tapped Pitch Normal"];
            } else {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Tapped Pitch Cancel"];
            }
        }
    }
    
}

- (IBAction)leftButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


@end
