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
#import "PhoneContact.h"
#import "UIViewController+Alerts.h"
#import "ContactManager.h"
#import "YSRecordProgressView.h"
#import "NextButton.h"
#import "YapsViewController.h"
#import <STKAudioPlayer.h>

@interface AddTextViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *addTextToYapButton;
@property (weak, nonatomic) IBOutlet YSColorPicker *colorPicker;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *flashbackImageView;
@property (strong, nonatomic) IBOutlet UILabel *contactLabel;
@property (strong, nonatomic) IBOutlet NextButton *continueButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (strong, nonatomic) STKAudioPlayer* player;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton1;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton2;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton3;
@property (strong, nonatomic) IBOutlet UIButton *resetPitchButton;
@property (nonatomic) CGFloat pitchShiftValue;

- (IBAction)didTapAddTextButton;
- (IBAction)didTapPitchButton1;
- (IBAction)didTapPitchButton2;
- (IBAction)didTapPitchButton3;
- (IBAction)didTapResetPitchButton;

#define VIEWED_SPOTIFY_ALERT_KEY @"yaptap.ViewedSpotifyAlert"

@end

@implementation AddTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Add Text Page"];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.progressView.progress = self.yapBuilder.duration/10;
    
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textView.delegate = self;
    self.colorPicker.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.textView];
    
    if (self.yapBuilder.contacts.count > 0) {
        PhoneContact *contact = self.yapBuilder.contacts.firstObject;
        self.contactLabel.text = [NSString stringWithFormat:@"Send to\n%@", contact.name];
        self.contactLabel.numberOfLines = 2;
    } else {
        self.contactLabel.text = @"";
    }
    
    double delay = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.continueButton startToPulsate];
    });
    
    [self.textView setTintColor:[UIColor whiteColor]];
    
    double delay2 = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.player = [STKAudioPlayer new];
    });
    
    if ([self.yapBuilder.messageType  isEqual: @"VoiceMessage"]) {
        self.changePitchButton1.hidden = NO;
    }
    
    //self.pitchSlider.maximumValue = 1.0;
    //self.pitchSlider.minimumValue = -1.0;
    //self.pitchSlider.value = 0.0;
    //[self.pitchSlider addTarget:self action:@selector(didChangePitch) forControlEvents:UIControlEventTouchUpInside];
    //[self.pitchSlider addTarget:self action:@selector(didChangePitch) forControlEvents:UIControlEventTouchUpOutside];
}
/*
- (void) didChangePitch
{
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSLog(@"%f", self.pitchSlider.value);
    self.player.pitchShift = self.pitchSlider.value;
    [self.player playURL:outputFileURL];
}
*/

- (void) didTapPitchButton1
{
    [UIView animateWithDuration:.8
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.changePitchButton2.alpha = 1;
                         self.changePitchButton3.alpha = 1;
                         self.resetPitchButton.alpha = 1;
                     }
                     completion:nil];
    
    UIImage *buttonImage = [UIImage imageNamed:@"BalloonYellow10.png"];
    [self.changePitchButton1 setImage:buttonImage forState:UIControlStateNormal];
    UIImage *whiteBalloonImage = [UIImage imageNamed:@"Balloon10.png"];
    [self.changePitchButton2 setImage:whiteBalloonImage forState:UIControlStateNormal];
    [self.changePitchButton3 setImage:whiteBalloonImage forState:UIControlStateNormal];
    
    if (self.isiPhone5Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone5.png"]];
    } else if (self.isiPhone4Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone4.png"]];
    } else {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellow.png"]];
    }

    self.pitchShiftValue = 1.0;
    [self playAudioWithPitch:self.pitchShiftValue];
}

- (void) didTapPitchButton2
{    
    UIImage *buttonImage = [UIImage imageNamed:@"BalloonGreen10.png"];
    [self.changePitchButton2 setImage:buttonImage forState:UIControlStateNormal];
    UIImage *whiteBalloonImage = [UIImage imageNamed:@"Balloon10.png"];
    [self.changePitchButton1 setImage:whiteBalloonImage forState:UIControlStateNormal];
    [self.changePitchButton3 setImage:whiteBalloonImage forState:UIControlStateNormal];
    
    if (self.isiPhone5Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone5.png"]];
    } else if (self.isiPhone4Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone4.png"]];
    } else {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreen.png"]];
    }
    
    self.pitchShiftValue = 0.5;
    [self playAudioWithPitch:self.pitchShiftValue];
}

- (void) didTapPitchButton3
{
    UIImage *buttonImage = [UIImage imageNamed:@"BalloonLightBlue10.png"];
    [self.changePitchButton3 setImage:buttonImage forState:UIControlStateNormal];
    UIImage *whiteBalloonImage = [UIImage imageNamed:@"Balloon10.png"];
    [self.changePitchButton1 setImage:whiteBalloonImage forState:UIControlStateNormal];
    [self.changePitchButton2 setImage:whiteBalloonImage forState:UIControlStateNormal];
    
    if (self.isiPhone5Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone5.png"]];
    } else if (self.isiPhone4Size) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone4.png"]];
    } else {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlue.png"]];
    }
    
    self.pitchShiftValue = -0.4;
    [self playAudioWithPitch:self.pitchShiftValue];
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

- (void) didTapResetPitchButton {
    [self resetProgressViewColor];
    self.player.pitchShift = 0;
    
    UIImage *whiteBalloonImage = [UIImage imageNamed:@"Balloon10.png"];
    [self.changePitchButton1 setImage:whiteBalloonImage forState:UIControlStateNormal];
    [self.changePitchButton2 setImage:whiteBalloonImage forState:UIControlStateNormal];
    [self.changePitchButton3 setImage:whiteBalloonImage forState:UIControlStateNormal];
    
    [UIView animateWithDuration:.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.changePitchButton2.alpha = 0;
                         self.changePitchButton3.alpha = 0;
                         self.resetPitchButton.alpha = 0;
                     }
                     completion:nil];
    
    [self.player stop];
}

- (void) resetProgressViewColor {
    if (IS_IPHONE_5_SIZE) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRediPhone5.png"]];
    } else if (IS_IPHONE_4_SIZE) {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRediPhone4.png"]];
    } else {
        [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewRed.png"]];
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
    [self.player stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;
        vc.yapBuilder = self.yapBuilder;
    } else if ([@"YapsViewControllerSegue" isEqualToString:segue.identifier]) {
        YapsViewController *vc = segue.destinationViewController;
        vc.pendingYaps = sender;
        vc.comingFromContactsOrAddTextPage = YES;
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) sendYap
{
    [self disableContinueButton];
    
    if ([self internetIsNotReachable]) {
        [self showNoInternetAlert];
        [self enableContinueButton];
    } else {
        __weak AddTextViewController *weakSelf = self;
        
        NSArray *pendingYaps =
        [[API sharedAPI] sendYapBuilder:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        [self enableContinueButton];
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.yapBuilder.contacts];
                            
                            double delay = 1.0;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if ([self.yapBuilder.messageType isEqual: @"SpotifyMessage"] && !self.didViewSpotifyAlert) {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Heads Up"
                                                                                    message:@"When you send a song snippet on YapTap, the recipient can listen to the full song on Spotify!"
                                                                                   delegate:nil
                                                                          cancelButtonTitle:@"OK"
                                                                          otherButtonTitles:nil];
                                    [alert show];
                                    [self viewedSpotifyAlert];
                                }
                            });
                        } else {
                            double delay = 0.5;
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                NSLog(@"Error: %@", error);
                                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Yap Didn't Send!"];
                                [self enableContinueButton]; // Adding this line a second time just in case - doesn't always get triggered above for some reason
                            });
                        }
                    }];
        NSLog(@"Sent yaps call");
        [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:pendingYaps];
    }
}



- (IBAction)didTapNextButton:(UIButton *)sender
{
    self.yapBuilder.text = self.textView.text;
    self.yapBuilder.color = self.view.backgroundColor;
    // To get pitch value in 'cent' units, multiply self.pitchShiftValue by STK_PITCHSHIFT_TRANSFORM
    self.yapBuilder.pitchValueInCentUnits = [NSNumber numberWithFloat:(1000*self.pitchShiftValue)];
    
    if (self.yapBuilder.contacts.count > 0) {
        [self sendYap];
    } else {
        [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Continue On Add Text Page"];
}
- (IBAction)didTapBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)didTapAddTextButton {
    [self.textView becomeFirstResponder];
    self.textView.hidden = NO;
    self.addTextToYapButton.hidden = YES;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Add Text Button"];
}

-(void) disableContinueButton
{
    self.continueButton.userInteractionEnabled = NO;
    [self.continueButton setImage:[UIImage imageNamed:@"WhiteCircle.png"] forState:UIControlStateNormal];
    [self.loadingSpinner startAnimating];
    NSLog(@"LOADING INDICATOR STARTED SPINNING");
}

-(void) enableContinueButton
{
    self.continueButton.userInteractionEnabled = YES;
    [self.loadingSpinner stopAnimating];
    NSLog(@"LOADING INDICATOR STOPPED SPINNING");
    [self.continueButton setImage:[UIImage imageNamed:@"ArrowWhite.png"] forState:UIControlStateNormal];
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

#pragma mark - Spotify Alert Methods

- (void) viewedSpotifyAlert
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_SPOTIFY_ALERT_KEY];
}

- (BOOL) didViewSpotifyAlert
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_SPOTIFY_ALERT_KEY];
}

@end
