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
@property (nonatomic,strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton1;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton2;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton3;
@property (strong, nonatomic) IBOutlet UIButton *changePitchButton4;

- (IBAction)didTapAddTextButton;
- (IBAction)didTapChangePitchButton1;


#define VIEWED_SPOTIFY_ALERT_KEY @"yaptap.ViewedSpotifyAlert"

@end

@implementation AddTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Add Text Page"];
    //self.pitchSlider.maximumValue = 1.0;
    //self.pitchSlider.minimumValue = -1.0;
    //self.pitchSlider.value = 0.0;
    //[self.pitchSlider addTarget:self action:@selector(didChangePitch) forControlEvents:UIControlEventTouchUpInside];
    //[self.pitchSlider addTarget:self action:@selector(didChangePitch) forControlEvents:UIControlEventTouchUpOutside];
    //self.player = [STKAudioPlayer new];
    
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
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures:)];
    self.longPressGestureRecognizer.minimumPressDuration = 1.0f;
    self.longPressGestureRecognizer.allowableMovement = 100.0f;
    
    [self.changePitchButton1 addGestureRecognizer:self.longPressGestureRecognizer];
    
    double delay2 = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.player = [STKAudioPlayer new];
    });
    
    if ([self.yapBuilder.messageType  isEqual: @"VoiceMessage"]) {
        self.changePitchButton1.hidden = NO;
    }
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)sender
{
    if ([sender isEqual:self.longPressGestureRecognizer]) {
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            NSLog(@"Long Press");
            self.changePitchButton2.hidden = NO;
            self.changePitchButton3.hidden = NO;
            self.changePitchButton4.hidden = NO;
        }
    }
}

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

- (void) didTapChangePitchButton1
{
    if (self.player.pitchShift != 1.0) {
        UIImage *buttonImage = [UIImage imageNamed:@"Balloon3Yellow.png"];
        [self.changePitchButton1 setImage:buttonImage forState:UIControlStateNormal];
        self.progressView.progressViewColor = [UIColor yellowColor]; // TODO: make this work
        
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"MyAudioMemo.m4a",
                                   nil];
        NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
        NSLog(@"%f", self.pitchSlider.value);
        self.player.pitchShift = 1.0; //self.pitchSlider.value;
        [self.player playURL:outputFileURL];
    } else {
        UIImage *buttonImage = [UIImage imageNamed:@"Balloon3.png"];
        [self.changePitchButton1 setImage:buttonImage forState:UIControlStateNormal];
        self.progressView.progressViewColor = THEME_RED_COLOR;

        [self.player stop];
        self.player.pitchShift = 0.0;
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
        vc.yapBuilder = self.yapBuilder;
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
        
        [[API sharedAPI] sendYapBuilder:self.yapBuilder
                    withCallback:^(BOOL success, NSError *error) {
                        [self enableContinueButton];
                        if (success) {
                            [[ContactManager sharedContactManager] sentYapTo:self.yapBuilder.contacts];
                            [weakSelf performSegueWithIdentifier:@"YapsViewControllerSegue" sender:self];
                            
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
    }

}

- (IBAction)didTapNextButton:(UIButton *)sender {
    self.yapBuilder.text = self.textView.text;
    self.yapBuilder.color = self.view.backgroundColor;
    
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
