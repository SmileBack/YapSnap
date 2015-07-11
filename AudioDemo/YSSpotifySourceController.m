//
//  YSSpotifySourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSSpotifySourceController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import "SpotifyAPI.h"
#import "SpotifyTrackView.h"
#import "OpenInSpotifyAlertView.h"
#import <AVFoundation/AVAudioSession.h>
#import "AppDelegate.h"
#import "SpotifyTrackFactory.h"
#import "UIViewController+MJPopupViewController.h"
#import "SearchArtistAlertView.h"
#import "YTTrackGroup.h"

@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;
@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic, strong) NSString *alertViewString;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (strong, nonatomic) IBOutlet UIButton *resetButton;
@property (nonatomic, strong) NSDictionary *typeToGenreMap;
@property (strong, nonatomic) UIButton *spotifyButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *carouselHeightConstraint;
@property (strong, nonatomic) IBOutlet UIButton *bottomButton;
@property (strong, nonatomic) UIButton *artistButton;
@property (strong, nonatomic) IBOutlet UIImageView *magnifyingGlassImageView;
@property (nonatomic, strong) NSString *artistNameString;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *carouselYConstraint;
@property (strong, nonatomic) UIButton *artistButtonHack;
@property (nonatomic, strong) NSString *lastShownPlaylist;
@property (nonatomic, strong) NSMutableArray *tracks;
@property (nonatomic, strong) YSTrack *explainerTrack;
@property (strong, nonatomic) IBOutlet UIView *categoryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryModeButtonWidthConstraint;
@property (nonatomic) CGFloat maxStringSizeWidth;
@property (nonatomic) BOOL isShowingFillerTracks;

@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryOne;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryTwo;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryThree;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryFour;
@property (strong, nonatomic) YTTrackGroup *trackGroupOnboarding;
@property (strong, nonatomic) YTTrackGroup *trackGroupPool;

// tapCategoryButton
@property (strong, nonatomic) IBOutlet UIButton *categoryButtonOne;
@property (strong, nonatomic) IBOutlet UIButton *categoryButtonTwo;
@property (strong, nonatomic) IBOutlet UIButton *categoryButtonThree;
@property (strong, nonatomic) IBOutlet UIButton *categoryButtonFour;

// didTapCategoryButton
- (IBAction)didTapCategoryButtonOne:(UIButton*)button;
- (IBAction)didTapCategoryButtonTwo:(UIButton*)button;
- (IBAction)didTapCategoryButtonThree:(UIButton*)button;
- (IBAction)didTapCategoryButtonFour:(UIButton*)button;

- (IBAction)didTapResetButton;
- (IBAction)didTapCategoryModeButton;
 
@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Spotify Page"];

    //[SpotifyAPI sharedApi]; //Activate to get access token
    
    [self setupSearchBox];
    
    if ([self internetIsNotReachable]) {
        NSLog(@"Internet is not reachable");
    } else {
        NSLog(@"Internet is reachable");
    }
    
    [self setupGestureRecognizers];
    
    [self setupNotifications];
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCarousel:)];
    longPress.cancelsTouchesInView = NO;
    longPress.minimumPressDuration = 0.2;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCarousel:)];
    tap.cancelsTouchesInView = NO;
    [self.carousel addGestureRecognizer:tap];
    [self.carousel addGestureRecognizer:longPress];
    
    [self setupConstraints];
    
    [self createArtistButtonHack];
    
    self.categoryView.backgroundColor = THEME_BACKGROUND_COLOR;
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    self.searchBox.backgroundColor = THEME_BACKGROUND_COLOR;
    self.artistButton.titleLabel.textColor = THEME_SECONDARY_COLOR;
    
    [self createTrackGroups];
    
    [self setupCategoryButtons];
}

- (void) setupConstraints {
    CGFloat carouselHeight = 0.0;

    if (IS_IPHONE_4_SIZE) {
        carouselHeight = 140; // 69; 138*100
        //self.categoryButtonFiveBottomConstraint.constant = 120;
//        self.categoryButtonFiveWidthConstraint.constant = 75;
//        self.categoryModeButtonWidthConstraint.constant = 60;
    } else if (IS_IPHONE_5_SIZE) {
        carouselHeight = 200; // 99; 198*100
//        self.categoryButtonFiveBottomConstraint.constant = 120;
//        self.categoryButtonFiveWidthConstraint.constant = 80;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        carouselHeight = 290; // 144; (288*100) *1.5
//        self.categoryViewBottomConstraint.constant = 150;
//        self.categoryButtonFiveBottomConstraint.constant = 140;
//        self.categoryButtonFiveWidthConstraint.constant = 105;
//        self.categoryModeButtonWidthConstraint.constant = 80;
    } else {
        carouselHeight = 240; // 119; (238*100) *1.172  279*117
//        self.categoryButtonFiveBottomConstraint.constant = 160;
//       self.categoryButtonFiveWidthConstraint.constant = 95;
    }
    self.carouselHeightConstraint.constant = carouselHeight;
    
    if (IS_IPHONE_6_SIZE) {
        self.carouselYConstraint.constant = 50;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.carouselYConstraint.constant = 60;
    }
}

- (void) createArtistButtonHack {
    self.artistButtonHack = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.artistButtonHack addTarget:self
               action:@selector(didTapArtistButtonHack)
     forControlEvents:UIControlEventTouchUpInside];
    /*
    self.artistButtonHack.frame = CGRectMake((self.view.bounds.size.width - self.carouselHeightConstraint.constant)/2, 340, self.carouselHeightConstraint.constant, 24.0);
     */
    [self.view addSubview:self.artistButtonHack];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    
    if ([self shouldLoadSongsFromPool]) {
        if (!self.didPlaySongForFirstTime) {
            [self retrieveAndLoadTracksForCategory:self.trackGroupOnboarding];
        } else {
            [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.bottomButton.hidden = NO;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    [self resetSuggestedSongsIfNeeded];
}

- (void) setupGestureRecognizers {
    UITapGestureRecognizer *tappedSpotifyView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedSpotifyView)];
    tappedSpotifyView.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tappedSpotifyView];
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:DISMISS_KEYBOARD_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.view endEditing:YES];
                    }];
    
    [center addObserverForName:UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Spotify VC received threshold notification");
                        [self showBannerWithText:@"Keep Holding" temporary:YES];
                    }];
    
    [center addObserverForName:LISTENED_TO_CLIP_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self hideAlbumBannerWithFadeAnimation:YES];
                        self.bottomButton.hidden = YES;
                    }];
    
    [center addObserverForName:RESET_BANNER_UI
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        //[self hideAlbumBannerWithFadeAnimation:YES];
                        self.bottomButton.hidden = NO;
                    }];
    
    [center addObserverForName:UIApplicationWillEnterForegroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        if (!self.songs) {
                            self.carousel.alpha = 0;
                        }

                        if ([self shouldLoadSongsFromPool]) {
                            if (!self.didPlaySongForFirstTime) {
                                [self retrieveAndLoadTracksForCategory:self.trackGroupOnboarding];
                            } else {
                                [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
                            }
                        }
                    }];
    
    [center addObserverForName:UIApplicationDidEnterBackgroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        if (self.categoryView.alpha == 1) {
                            // Hide Category View
                            self.categoryView.alpha = 0;
                            [self.bottomButton setBackgroundImage:[UIImage imageNamed:@"CategoryButtonImageNew2.png"] forState:UIControlStateNormal];
                            self.artistButtonHack.hidden = NO;
                        }
                        [self.view endEditing:YES];
                        [self resetSuggestedSongsIfNeeded];
                    }];
}

- (void)tappedSpotifyView {
    NSLog(@"Tapped Spotify View");
    if (self.searchBox.isFirstResponder) {
        [self searchWithTextInTextField:self.searchBox];
    } else {
        // if carousel isn't showing
        if (self.carousel.alpha < 1) {
            [self.searchBox becomeFirstResponder];
        }
    }
}

- (IBAction) didTapResetButton {
    self.carousel.alpha = 0;
    [self resetUI];
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.searchBox becomeFirstResponder];
    });
}

#pragma mark - Track Category Stuff

- (void) createTrackGroups {
    self.trackGroupCategoryOne = [YTTrackGroup new];
    self.trackGroupCategoryOne.name = @"Nostalgic";
    self.trackGroupCategoryOne.apiString = @"nostalgic_tracks";
    
    self.trackGroupCategoryTwo = [YTTrackGroup new];
    self.trackGroupCategoryTwo.name = @"Funny";
    self.trackGroupCategoryTwo.apiString = @"funny_tracks";
    
    self.trackGroupCategoryThree = [YTTrackGroup new];
    self.trackGroupCategoryThree.name = @"Flirtatious";
    self.trackGroupCategoryThree.apiString = @"flirtatious_tracks";
    
    self.trackGroupCategoryFour = [YTTrackGroup new];
    self.trackGroupCategoryFour.name = @"Popular";
    self.trackGroupCategoryFour.apiString = @"trending_tracks";
    
    self.trackGroupOnboarding = [YTTrackGroup new];
    self.trackGroupOnboarding.name = @"Onboarding";
    self.trackGroupOnboarding.apiString = @"onboarding_tracks";
    
    self.trackGroupPool = [YTTrackGroup new];
    self.trackGroupPool.name = @"Pool";
    self.trackGroupPool.apiString = @"pool_tracks";
}

-(void) setupCategoryButtons {
    self.categoryButtonOne.layer.cornerRadius = 30; //self.categoryButtonFiveWidthConstraint.constant/2;
    self.categoryButtonOne.layer.borderWidth = 1;
    self.categoryButtonOne.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
    self.categoryButtonOne.backgroundColor = THEME_SECONDARY_COLOR; //THEME_BACKGROUND_COLOR;
    [self.categoryButtonOne setTitleColor: THEME_BACKGROUND_COLOR forState:UIControlStateNormal]; //THEME_SECONDARY_COLOR forState:UIControlStateNormal];
    [self.categoryButtonOne setTitle:self.trackGroupCategoryOne.name forState:UIControlStateNormal];
    
    self.categoryButtonTwo.layer.cornerRadius = 30; //self.categoryButtonFiveWidthConstraint.constant/2;
    self.categoryButtonTwo.layer.borderWidth = 1;
    self.categoryButtonTwo.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
    self.categoryButtonTwo.backgroundColor = THEME_SECONDARY_COLOR; //THEME_BACKGROUND_COLOR;THEME_BACKGROUND_COLOR;
    [self.categoryButtonTwo setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal]; //THEME_SECONDARY_COLOR forState:UIControlStateNormal];
    [self.categoryButtonTwo setTitle:self.trackGroupCategoryTwo.name forState:UIControlStateNormal];
    
    self.categoryButtonThree.layer.cornerRadius = 30; //self.categoryButtonFiveWidthConstraint.constant/2;
    self.categoryButtonThree.layer.borderWidth = 1;
    self.categoryButtonThree.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
    self.categoryButtonThree.backgroundColor = THEME_SECONDARY_COLOR; //THEME_BACKGROUND_COLOR;
    [self.categoryButtonThree setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal]; //THEME_SECONDARY_COLOR forState:UIControlStateNormal];
    [self.categoryButtonThree setTitle:self.trackGroupCategoryThree.name forState:UIControlStateNormal];
    
    self.categoryButtonFour.layer.cornerRadius = 30; //self.categoryButtonFiveWidthConstraint.constant/2;
    self.categoryButtonFour.layer.borderWidth = 1;
    self.categoryButtonFour.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
    self.categoryButtonFour.backgroundColor = THEME_SECONDARY_COLOR; //THEME_BACKGROUND_COLOR;
    [self.categoryButtonFour setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal]; //THEME_SECONDARY_COLOR forState:UIControlStateNormal];
    [self.categoryButtonFour setTitle:self.trackGroupCategoryFour.name forState:UIControlStateNormal];
}

-(IBAction) didTapCategoryModeButton {
    [self switchCategoryMode];
    
    //[self retrieveTracksForCategory:@"Happy"];
}

-(void) switchCategoryMode {
    if (self.categoryView.alpha == 0) {
        // Show Category View
        self.categoryView.alpha = 1;
        [self.bottomButton setBackgroundImage:[UIImage imageNamed:@"CategoryBackButtonImage.png"] forState:UIControlStateNormal];
        self.searchBox.text = @"";
        [self hideResetButton];
        self.artistButtonHack.hidden = YES;
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Category Mode Button (Show)"];
    } else {
        // Hide Category View
        self.categoryView.alpha = 0;
        [self.bottomButton setBackgroundImage:[UIImage imageNamed:@"CategoryButtonImageNew2.png"] forState:UIControlStateNormal];
        self.artistButtonHack.hidden = NO;
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Category Mode Button (Hide)"];
    }
}

-(void) didTapCategoryButtonOne:(UIButton *)button {
    [self tappedCategoryButtonForTrackGroup:self.trackGroupCategoryOne];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Category One Button"];
}

-(void) didTapCategoryButtonTwo:(UIButton *)button {
    [self tappedCategoryButtonForTrackGroup:self.trackGroupCategoryTwo];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Category Two Button"];
}

-(void) didTapCategoryButtonThree:(UIButton *)button {
    [self tappedCategoryButtonForTrackGroup:self.trackGroupCategoryThree];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Category Three Button"];
}

-(void) didTapCategoryButtonFour:(UIButton *)button {
    [self tappedCategoryButtonForTrackGroup:self.trackGroupCategoryFour];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Category Four Button"];
}

- (void) tappedCategoryButtonForTrackGroup:(YTTrackGroup*)trackGroup {
    self.carousel.alpha = 0;
    self.searchBox.text = trackGroup.name;
    self.resetButton.alpha = 1;
    self.categoryView.alpha = 0;
    [self.bottomButton setBackgroundImage:[UIImage imageNamed:@"CategoryButtonImageNew2.png"] forState:UIControlStateNormal];
    [self retrieveAndLoadTracksForCategory:trackGroup];
    self.artistButtonHack.hidden = NO;
}

- (void) retrieveAndLoadTracksForCategory:(YTTrackGroup *)trackGroup
{
    [self.loadingIndicator startAnimating];
    
    if (trackGroup == self.trackGroupOnboarding || trackGroup == self.trackGroupPool) {
        self.isShowingFillerTracks = YES;
    } else {
        self.isShowingFillerTracks = NO;
    }

    if (trackGroup.songs) {
        self.songs = trackGroup.songs;
        [self loadSongsForCategory:trackGroup];
    } else {
        [[API sharedAPI] retrieveTracksForCategory:trackGroup withCallback:^(NSArray *songs, NSError *error) {
            if (songs) {
                trackGroup.songs = songs;
                self.songs = trackGroup.songs;
                [self loadSongsForCategory:trackGroup];
            } else {
                NSLog(@"Something went wrong");
            }
        }];
    }
}

-(void)createExplainerTrack {
    if (!self.explainerTrack) {
        self.explainerTrack = [YSTrack new];
        self.explainerTrack.name = @"";
        self.explainerTrack.spotifyID = @"";
        self.explainerTrack.previewURL = @"";
        self.explainerTrack.artistName = @"";
        self.explainerTrack.albumName = @"";
        self.explainerTrack.spotifyURL = @"";
        self.explainerTrack.isExplainerTrack = YES;
    }
}

- (void) loadSongsForCategory:(YTTrackGroup *)trackGroup
{ 
    if (!self.explainerTrack) {
        [self createExplainerTrack];
    }
    
    if (trackGroup == self.trackGroupOnboarding) {
        self.songs = [self.songs arrayByAddingObjectsFromArray:@[self.explainerTrack]];
    } else {
        
        // Shuffle all
        NSArray *shuffledSongs = [self shuffleTracks:[NSMutableArray arrayWithArray:self.songs]];
        
        if (trackGroup == self.trackGroupPool) {
            // Only take first five
            NSArray *firstFiveTracks = @[shuffledSongs[0], shuffledSongs[1], shuffledSongs[2], shuffledSongs[3], shuffledSongs[4]];
            self.songs = [firstFiveTracks arrayByAddingObjectsFromArray:@[self.explainerTrack]];
        } else {
            self.songs = shuffledSongs;
        }
    }
    
    [self.loadingIndicator stopAnimating];
    self.carousel.currentItemIndex = 0;
    [self.carousel reloadData];
    self.carousel.alpha = 1;
}

- (NSMutableArray*) shuffleTracks:(NSMutableArray *)tracks {
    NSUInteger count = [tracks count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [tracks exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    return tracks;
}

-(BOOL) shouldLoadSongsFromPool {
    YSTrack *lastTrack = [self.songs lastObject];
    if (!self.songs || self.songs.count < 1 || lastTrack.isExplainerTrack) {
        return YES;
    } else {
        return NO;
    }
}

- (void) resetSuggestedSongsIfNeeded {
    YSTrack *lastTrack = [self.songs lastObject];
    if (self.songs.count < 1 || lastTrack.isExplainerTrack) {
        self.songs = nil;
        [self.carousel reloadData];
    }
}

#pragma mark - Spotify Search

- (void) searchForTracksWithString:(NSString *)searchString
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched Songs"];
    [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];
    
    self.songs = nil;
    [self.carousel reloadData];
    self.carousel.alpha = 1;
    self.loadingIndicator.alpha = 1;
    [self.loadingIndicator startAnimating];
    
    __weak YSSpotifySourceController *weakSelf = self;
    void (^callback)(NSArray*, NSError*) = ^(NSArray *songs, NSError *error) {
        if (songs) {
            self.isShowingFillerTracks = NO;
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            if (songs.count == 0) {
                [self.loadingIndicator stopAnimating];
                
                NSLog(@"No Songs Returned For Search Query");
                
                double delay = 0.2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
                });
                
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
            }
        } else if (error) {
            [self.loadingIndicator stopAnimating];
            
            if ([self internetIsNotReachable]) {
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
                });
            } else {
                NSLog(@"Error Returning Songs %@", error);
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Something Went Wrong! Try Again."];
                });
                
                [mixpanel track:@"Spotify Error - search (other)"];
            }
        }
    };
    
    NSLog(@"Search String: -%@-", searchString);
    NSLog(@"TrackGroupCategoryTwo Name: -%@-", self.trackGroupCategoryTwo.name);
    if ([searchString isEqualToString:self.trackGroupCategoryOne.name]) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupCategoryOne];
    } else if ([searchString isEqualToString:self.trackGroupCategoryTwo.name]) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupCategoryTwo];
    } else if ([searchString isEqualToString:self.trackGroupCategoryThree.name]) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupCategoryThree];
    } else if ([searchString isEqualToString:self.trackGroupCategoryFour.name]) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupCategoryFour];
    } else {
        [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForSearchString:searchString withCallback:callback];
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) setPlayer:(STKAudioPlayer *)player
{
    if (_player) {
        [_player stop];
    }
    _player = player;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (YapBuilder *) getYapBuilder
{
    YapBuilder *builder = [YapBuilder new];
    
    builder.messageType = MESSAGE_TYPE_SPOTIFY;
    builder.track = self.songs[self.carousel.currentItemIndex];

    NSLog(@"Seconds to fast forward: %@", builder.track.secondsToFastForward);
    
    return builder;
}

#pragma mark - Search box stuff
- (void) setupSearchBox
{
    self.searchBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.searchBox.textColor = THEME_SECONDARY_COLOR;
    [self.searchBox setTintColor:THEME_SECONDARY_COLOR];
    self.searchBox.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    self.searchBox.delegate = self;
    [self.searchBox addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.searchBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
    //self.searchBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor] }];
    
    self.searchBox.layer.cornerRadius= 1.0f;
    self.searchBox.layer.masksToBounds=YES;
    self.searchBox.layer.borderColor=[UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    self.searchBox.layer.borderWidth= 1.0f;
}



-(void)textFieldDidChange:(UITextField *)searchBox {
    if ([self.searchBox.text length] == 0) {
        NSLog(@"Empty String");
        self.resetButton.alpha = 0;
    } else {
        [self updateVisibilityOfMagnifyingGlassAndResetButtons];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"Textfield did begin editing");
    self.carousel.scrollEnabled = NO;
    self.carousel.alpha = 0;
    self.songs = nil;

    [self resetBottomBannerUI];
    
    if (self.categoryView.alpha == 1) {
        [self switchCategoryMode];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"Textfield did end editing");
    [self setUserInteractionEnabled:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Remove extra space at end of string
    [self searchWithTextInTextField:textField];
    return YES;
}

- (void)searchWithTextInTextField:(UITextField*)textField {
    self.searchBox.text = [self.searchBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self.view endEditing:YES];
    if ([self.searchBox.text length] > 0) {
        [self searchForTracksWithString:self.searchBox.text];
        [[API sharedAPI] sendSearchTerm:textField.text withCallback:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"Sent search term metric");
            } else {
                NSLog(@"Failed to send search term metric");
            }
        }];
    } else {
        if ([self shouldLoadSongsFromPool]) {
            if (!self.didPlaySongForFirstTime) {
                [self retrieveAndLoadTracksForCategory:self.trackGroupOnboarding];
            } else {
                [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
            }
        }
    }
}

#pragma mark - iCarousel Stuff
- (NSInteger) numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.songs.count;
}

- (UIView *) carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    YSTrack *track = self.songs[index];
    SpotifyTrackView *trackView;

    if (view && [view isKindOfClass:[SpotifyTrackView class]]) {
        trackView = (SpotifyTrackView *) view;
    } else {
        // TRACKVIEW
        CGFloat carouselHeight = self.carouselHeightConstraint.constant;
        CGRect frame = CGRectMake(0, 0, carouselHeight, carouselHeight);
        trackView = [[SpotifyTrackView alloc] initWithFrame:frame];
        
        // ALBUM IMAGE
        trackView.imageView = [[UIImageView alloc] initWithFrame:frame];
        [trackView addSubview:trackView.imageView];
        
        // SONG NAME LABEL
        trackView.songNameLabel = [[UILabel alloc]initWithFrame:
                           CGRectMake(0, carouselHeight + 6, carouselHeight, 25)];
        trackView.songNameLabel.textColor = THEME_SECONDARY_COLOR;
        trackView.songNameLabel.backgroundColor = [UIColor clearColor];
        trackView.songNameLabel.textAlignment = NSTextAlignmentCenter;
        CGFloat size = IS_IPHONE_4_SIZE ? 14 : 18;
        trackView.songNameLabel.font = [UIFont fontWithName:@"Futura-Medium" size:size];
        [trackView addSubview:trackView.songNameLabel];
        
        // ALBUM BUTTON
        trackView.albumImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.albumImageButton.frame = CGRectMake(0, 0, carouselHeight, carouselHeight);
        [trackView.albumImageButton setImage:nil forState:UIControlStateNormal];
        [trackView addSubview:trackView.albumImageButton];
        
        // SPOTIFY BUTTON
        trackView.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.spotifyButton.frame = CGRectMake(carouselHeight-40, 5, 35, 35);
        [trackView.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
        [trackView addSubview:trackView.spotifyButton];
        
        // ARTIST BUTTON
        trackView.artistButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [trackView.artistButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:14]];
        trackView.artistButton.backgroundColor = THEME_DARK_BLUE_COLOR;
        [trackView addSubview:trackView.artistButton];

        // SONG VERSION ONE BUTTON
        trackView.songVersionOneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.songVersionOneButton.frame = CGRectMake(5, carouselHeight -55, carouselHeight/2 - 6, 50);
        [trackView.songVersionOneButton addTarget:self action:@selector(tappedSongVersionOneButton:) forControlEvents:UIControlEventTouchDown];
        [trackView addSubview:trackView.songVersionOneButton];
        
            // Hack:
        UITapGestureRecognizer *tapGestureButtonOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shortTappedSongVersionOneButton)];
        tapGestureButtonOne.numberOfTapsRequired = 1;
        tapGestureButtonOne.numberOfTouchesRequired = 1;
        [trackView.songVersionOneButton addGestureRecognizer:tapGestureButtonOne];

        // SONG VERSION TWO BUTTON
        trackView.songVersionTwoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.songVersionTwoButton.frame = CGRectMake(carouselHeight/2 + 1, carouselHeight -55, carouselHeight/2 - 6, 50);
        [trackView.songVersionTwoButton addTarget:self action:@selector(tappedSongVersionTwoButton:) forControlEvents:UIControlEventTouchDown];
        [trackView addSubview:trackView.songVersionTwoButton];
        
            // Hack:
        UITapGestureRecognizer *tapGestureButtonTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shortTappedSongVersionTwoButton)];
        tapGestureButtonTwo.numberOfTapsRequired = 1;
        tapGestureButtonTwo.numberOfTouchesRequired = 1;
        [trackView.songVersionTwoButton addGestureRecognizer:tapGestureButtonTwo];

        // RIBBON IMAGE
        trackView.ribbonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
        trackView.ribbonImageView.image = [UIImage imageNamed:@"TrendingRibbon6.png"];
        [trackView addSubview:trackView.ribbonImageView];
        
        // ALBUM BANNER LABEL
        trackView.bannerLabel = [[UILabel alloc]initWithFrame:
                                               CGRectMake(0, 0, carouselHeight, 42)];
        /*
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, 41.0f, trackView.bannerLabel.frame.size.width, 2.0f);
        bottomBorder.backgroundColor = [THEME_SECONDARY_COLOR CGColor];
        [trackView.bannerLabel.layer addSublayer:bottomBorder];
         */
        
        trackView.bannerLabel.backgroundColor = THEME_RED_COLOR;
        trackView.bannerLabel.textAlignment = NSTextAlignmentCenter;
        trackView.bannerLabel.textColor = [UIColor whiteColor];
        trackView.bannerLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        trackView.bannerLabel.layer.borderWidth = 2;
        trackView.bannerLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [trackView addSubview:trackView.bannerLabel];
        
        trackView.imageView.layer.borderWidth = 2;
        trackView.imageView.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
        [trackView.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.05]];
        
        [trackView.spotifyButton addTarget:self action:@selector(confirmOpenInSpotify:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Set song version button selections
    if (IS_IPHONE_4_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone4.png"] forState:UIControlStateNormal];
    } else if (IS_IPHONE_6_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone6.png"] forState:UIControlStateNormal];
    } else {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelected.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelected.png"] forState:UIControlStateNormal];
    }
    
    track.secondsToFastForward = [NSNumber numberWithInt:0];
    
    if (track.imageURL) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
    } else {
        trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
    }
    
    if (track.isExplainerTrack) {
        trackView.imageView.image = [UIImage imageNamed:@"ExplainerTrackImage3.png"];
    }
    
    trackView.songNameLabel.text = track.name;
    trackView.spotifySongID = track.spotifyID;
    trackView.spotifyURL = track.spotifyURL;
    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
    [trackView.artistButton setTitleColor:THEME_SECONDARY_COLOR forState:UIControlStateNormal];
    CGSize stringsize = [[NSString stringWithFormat:@"by %@", track.artistName] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:14]}];
    if ((stringsize.width + 20) > self.carouselHeightConstraint.constant) {
        stringsize.width = self.carouselHeightConstraint.constant-24;
    }
    [trackView.artistButton setFrame:CGRectMake((self.carouselHeightConstraint.constant-stringsize.width-20)/2, self.carouselHeightConstraint.constant + 35, stringsize.width+20, stringsize.height + 8)];
    
    if (track.isExplainerTrack) {
        trackView.spotifyButton.hidden = YES;
        trackView.songVersionOneButton.hidden = YES;
        trackView.songVersionTwoButton.hidden = YES;
        trackView.albumImageButton.hidden = YES;
        trackView.artistButton.hidden = YES;
        trackView.songNameLabel.hidden = YES;
        trackView.bannerLabel.hidden = YES;
        trackView.ribbonImageView.hidden = YES;
    } else {
        trackView.spotifyButton.hidden = NO;
        trackView.songVersionOneButton.hidden = NO;
        trackView.songVersionTwoButton.hidden = NO;
        trackView.albumImageButton.hidden = NO;
        trackView.artistButton.hidden = NO;
        trackView.songNameLabel.hidden = NO;
        trackView.bannerLabel.hidden = NO;
        if (self.isShowingFillerTracks) {
            trackView.ribbonImageView.hidden = NO;
        } else {
            trackView.ribbonImageView.hidden = YES;
        }
    }
    
    // For Onboarding:
    if (!self.didPlaySongForFirstTime) {
        trackView.bannerLabel.alpha = 1;
        trackView.bannerLabel.text = @"Hold To Preview";
    } else {
        trackView.bannerLabel.alpha = 0;
    }
    
    return trackView;
}

- (void)didTapCarousel:(UITapGestureRecognizer*)tap {
    if (self.didPlaySongForFirstTime) {
        [self showBannerWithText:@"Hold To Preview" temporary:YES];
    } else {
        [self showBannerWithText:@"Keep Holding" temporary:NO];
    }
}

- (void) showBannerWithText:(NSString*)text temporary:(BOOL)temporary {
    SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
    trackView.bannerLabel.text = text;
    trackView.bannerLabel.alpha = 1;
    trackView.ribbonImageView.alpha = 0;
    
    if (temporary) {
        // Hide Label shortly after showing it
        double delay = 2.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 trackView.bannerLabel.alpha = 0;
                                 trackView.ribbonImageView.alpha = 1;
                             }
                             completion:nil];
        });
    }
}

- (void) hideAlbumBannerWithFadeAnimation:(BOOL)fadeAnimation {
    SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
    if (fadeAnimation) {
        [UIView animateWithDuration:.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             trackView.bannerLabel.alpha = 0;
                             trackView.ribbonImageView.alpha = 1;
                         }
                         completion:nil];
    } else {
        trackView.bannerLabel.alpha = 0;
    }
}

-(void)didLongPressCarousel:(UILongPressGestureRecognizer*)longPress {
    NSLog(@"Long Press State: %ld", (long)longPress.state);
    if(longPress.state == UIGestureRecognizerStateBegan)
    {
        [self startAudioCapture];
        [self showBannerWithText:@"Buffering..." temporary:NO];
    }
    else if(longPress.state == UIGestureRecognizerStateEnded
            || longPress.state == UIGestureRecognizerStateFailed
            || longPress.state == UIGestureRecognizerStateCancelled)
    {
        [self stopAudioCapture];
    }
}

- (void) tappedSongVersionOneButton:(UIButton *)button {
    NSLog(@"Tapped Song Version One Button");
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
        if (IS_IPHONE_4_SIZE) {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone4.png"] forState:UIControlStateNormal];
        } else if (IS_IPHONE_6_SIZE) {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone6.png"] forState:UIControlStateNormal];
        } else {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelected.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelected.png"] forState:UIControlStateNormal];
        }
        
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                break;
            }
        }
        selectedTrack.secondsToFastForward = [NSNumber numberWithInt:0];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version One"];
}

- (void) tappedSongVersionTwoButton:(UIButton *)button {
    NSLog(@"Tapped Song Version Two Button");
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
        if (IS_IPHONE_4_SIZE) {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelectediPhone4.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone4.png"] forState:UIControlStateNormal];
        } else if (IS_IPHONE_6_SIZE) {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelectediPhone6.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone6.png"] forState:UIControlStateNormal];
        } else {
            [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelected.png"] forState:UIControlStateNormal];
            [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelected.png"] forState:UIControlStateNormal];
        }
        
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                NSLog(@"selected track: %@", selectedTrack);
                break;
            }
        }
        selectedTrack.secondsToFastForward = [NSNumber numberWithInt:17];
    }
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version Two"];
}

- (void) shortTappedSongVersionOneButton {
    [self showBannerWithText:@"Song Clip 1" temporary:YES];
}

- (void) shortTappedSongVersionTwoButton {
    [self showBannerWithText:@"Song Clip 2" temporary:YES];
}

- (void) confirmOpenInSpotify:(UIButton *)button
{
    [self hideAlbumBannerWithFadeAnimation:NO];
    
    if([self.searchBox isFirstResponder])
    {
        NSLog(@"Search box is in focus");
        [self.view endEditing:YES];
    }
    else
    {
        NSLog(@"Search box not in focus");
        UIView *parent = button.superview;
        if ([parent isKindOfClass:[SpotifyTrackView class]]) {
            SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
            YSTrack *selectedTrack = nil;
            for (YSTrack *track in self.songs) {
                if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                    selectedTrack = track;
                    break;
                }
            }
            OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithTrack:selectedTrack];
            [alert show];
        }
    }
}

- (void)didTapArtistButtonHack {
    
    if (self.songs && self.songs.count > 0 && self.carousel.alpha == 1) {
        SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                break;
            }
        }

        if (selectedTrack && !selectedTrack.isExplainerTrack) {
            if (!self.tappedArtistButtonForFirstTime) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", selectedTrack.artistName]
                                                                    message:@"Tap an artist's name to see their top songs!"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Skip" otherButtonTitles:@"Continue", nil];
                [alertView show];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_TAP_ARTIST_BUTTON_FOR_FIRST_TIME_KEY];
            } else {
                [self searchForTracksWithString:selectedTrack.artistName];
                self.searchBox.text = selectedTrack.artistName;
                [self updateVisibilityOfMagnifyingGlassAndResetButtons];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Tapped Artist Hack Button"];
            }
        }
    }
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    NSLog(@"DidEndScrollingAnimation");
    
    SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
    YSTrack *selectedTrack = nil;
    for (YSTrack *track in self.songs) {
        if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
            selectedTrack = track;
            break;
        }
    }
    
    CGSize stringsize = [[NSString stringWithFormat:@"by %@", selectedTrack.artistName] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:14]}];
    
    if ((stringsize.width + 20) > self.carouselHeightConstraint.constant) {
        stringsize.width = self.carouselHeightConstraint.constant-24;
    }
    
    if (IS_IPHONE_4_SIZE) {
        //TODO
        [self.artistButtonHack setFrame:CGRectMake((self.view.bounds.size.width - (stringsize.width+20))/2, 401, stringsize.width+20, stringsize.height + 8)];
    } else if (IS_IPHONE_5_SIZE) {
        [self.artistButtonHack setFrame:CGRectMake((self.view.bounds.size.width - (stringsize.width+20))/2, 336, stringsize.width+20, stringsize.height + 8)];
    } else if (IS_IPHONE_6_PLUS_SIZE) {
            [self.artistButtonHack setFrame:CGRectMake((self.view.bounds.size.width - (stringsize.width+20))/2, 461, stringsize.width+20, stringsize.height + 8)];
    } else {
        [self.artistButtonHack setFrame:CGRectMake((self.view.bounds.size.width - (stringsize.width+20))/2, 401, stringsize.width+20, stringsize.height + 8)];
    }
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"Tapped carousel item"); //Carousel items are currently blocked by transparent album image button
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            return 1.1;
        }
        default:
        {
            return value;
        }
    }
}

- (void) stopAudioCapture
{
    if ((self.player.state & STKAudioPlayerStateRunning) != 0) {
        [self.player stop];
        [self setUserInteractionEnabled:YES]; // This is most likely redundant, but putting it here anyway just in case
        if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerdidFinishAudioCapture:)]) {
            [self.audioCaptureDelegate audioSourceControllerdidFinishAudioCapture:self];
        }
    }
}

- (void) setUserInteractionEnabled:(BOOL)enabled
{
    self.carousel.scrollEnabled = enabled;
    self.searchBox.enabled = enabled;
    self.resetButton.enabled = enabled;
}

#pragma mark - STKAudioPlayerDelegate

/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didStartPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didFinishBufferingSourceWithQueueItemId");
}

// We can get the reason why the player stopped!!!
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"audioPlayer didFinishPlayingQueueItemId; Reason: %u; Progress: %f; Duration: %f", stopReason, progress, duration);
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    NSLog(@"audioPlayer unexpected error: %u", errorCode);

    [self setUserInteractionEnabled:YES];
    [audioPlayer stop];
    if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceController:didReceieveUnexpectedError:)]) {
        [self.audioCaptureDelegate audioSourceController:self didReceieveUnexpectedError:[NSError errorWithDomain:@"YSSpotifySourceController" code:errorCode userInfo:nil]];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Unexpected Error - Spotify"];
}

/// Optionally implemented to get logging information from the STKAudioPlayer (used internally for debugging)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer logInfo:(NSString*)line
{
    NSLog(@"Log info: %@", line);
}
/// Raised when items queued items are cleared (usually because of a call to play, setDataSource or stop)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didCancelQueuedItems:(NSArray*)queuedItems
{
    NSLog(@"Did cancel queued items: %@", queuedItems);
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStateReady) {
        NSLog(@"state == STKAudioPlayerStateReady");
    }
    
    if (state == STKAudioPlayerStateRunning) {
        NSLog(@"state == STKAudioPlayerStateRunning");
    }
    
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        
        if (!self.playerAlreadyStartedPlayingForThisSong) {
            YSTrack *track = self.songs[self.carousel.currentItemIndex];
            if (track.secondsToFastForward.intValue > 0) {
                [audioPlayer seekToTime:track.secondsToFastForward.intValue];
            }
            // set self.playerAlreadyStartedPlayingForThisSong to True!
            self.playerAlreadyStartedPlayingForThisSong = YES;
            NSLog(@"Set playerAlreadyStartedPlayingForThisSong to TRUE");
        }
        
        if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerDidStartAudioCapture:)]) {
            [self.audioCaptureDelegate audioSourceControllerDidStartAudioCapture:self];
        }
        // Show Song Clip buttons when user is playing a song
        SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
        YSTrack *track = self.songs[self.carousel.currentItemIndex];
        trackView.songVersionOneButton.hidden = NO;
        trackView.songVersionTwoButton.hidden = NO;
        trackView.songVersionBackground.hidden = NO;
        track.songVersionButtonsAreShowing = YES;
        
        [self showBannerWithText:@"Playing..." temporary:NO];
        
        self.bottomButton.hidden = NO;
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_PLAY_SONG_FOR_FIRST_TIME_KEY];
    }
    
    if (state == STKAudioPlayerStateBuffering) {
        NSLog(@"state == STKAudioPlayerStateBuffering");
        if (self.playerAlreadyStartedPlayingForThisSong) {
            NSLog(@"Buffering for second time!");
            [[YTNotifications sharedNotifications] showBufferingText:@"Buffering (keep holding)"];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Buffering notification - Spotify"];
        }
    }
    
    if (state == STKAudioPlayerStatePaused) {
        NSLog(@"state == STKAudioPlayerStatePaused");
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"state == STKAudioPlayerStateStopped");
        [self stopLoadingSpinner];
        [self setUserInteractionEnabled:YES];
        
        // set self.playerAlreadyStartedPlayingForThisSong to FALSE!
        self.playerAlreadyStartedPlayingForThisSong = NO;
        NSLog(@"Set playerAlreadyStartedPlayingForThisSong to FALSE");
    }
    
    if (state == STKAudioPlayerStateError) {
        NSLog(@"state == STKAudioPlayerStateError");
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Player State Error - Spotify"];
    }
    
    if (state == STKAudioPlayerStateDisposed) {
        NSLog(@"state == STKAudioPlayerStateDisposed");
    }
}

#pragma mark - Implement public audio methods
- (BOOL) startAudioCapture
{
    if ([self internetIsNotReachable]){
        double delay = 0.1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
            [self hideAlbumBannerWithFadeAnimation:YES];
        });
        return NO;
    } else if (self.songs.count == 0) {
        NSLog(@"Can't Play Because No Song");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search Above"
                                                        message:@"Type a song, artist, or phrase above to find a song for your yap!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        [self setUserInteractionEnabled:NO];
        
        YSTrack *song = self.songs[self.carousel.currentItemIndex];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        if ([song.previewURL isEqual: [NSNull null]]) {
            NSLog(@"URL is Null");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Song Not Available"
                                                            message:@"Unfortunately this song is not currently available."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [self setUserInteractionEnabled:YES];
            [self stopLoadingSpinner];
            return NO;
        } else {
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            if (volume <= 0.125) {
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showBlueNotificationText:@"Turn Up The Volume!"];
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"Volume Notification - Spotify"];
                });
            }
            if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerWillStartAudioCapture:)]) {
                [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
            }
            
            NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
            NSLog(@"Playing URL: %@ %@ auth token", song.previewURL, headers ? @"with" : @"without");
            if (headers) {
                [self.player play:song.previewURL withHeaders:headers];
            } else {
                [self.player play:song.previewURL];
            }
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Played a Song"];
            [mixpanel.people increment:@"Played a Song #" by:[NSNumber numberWithInt:1]];
            return YES;
        }
    }
}

- (void) stopLoadingSpinner {
    double delay = 0.2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION object:nil];
    });
}

#pragma mark - Setting NSDefaults

- (BOOL) didPlaySongForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_PLAY_SONG_FOR_FIRST_TIME_KEY];
}

- (BOOL) tappedArtistButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_TAP_ARTIST_BUTTON_FOR_FIRST_TIME_KEY];
}

- (void) hideResetButton {
    self.resetButton.alpha = 0;
}

- (void) resetUI {
    [UIView animateWithDuration:.05
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
                         //NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor] }];
                         self.searchBox.attributedPlaceholder = string;
                         
                         [self hideResetButton];
                         self.loadingIndicator.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         self.searchBox.text = @"";
                     }];
}

- (void) resetBottomBannerUI {
    [[NSNotificationCenter defaultCenter] postNotificationName:RESET_BANNER_UI object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REMOVE_BOTTOM_BANNER_NOTIFICATION object:nil];
    self.bottomButton.hidden = NO;
}

- (void) updateVisibilityOfMagnifyingGlassAndResetButtons {
    CGSize stringsize = [[NSString stringWithFormat:@"%@", self.searchBox.text] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:18]}];
    //NSLog(@"STRING WIDTH %f", stringsize.width);
    
    if (IS_IPHONE_6_SIZE) {
        self.maxStringSizeWidth = 290;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.maxStringSizeWidth = 260;
    } else {
        self.maxStringSizeWidth = 210;
    }
    
    if (stringsize.width > self.maxStringSizeWidth) {
        self.resetButton.alpha = 0;
        self.magnifyingGlassImageView.hidden = YES;
    } else {
        [UIView animateWithDuration:.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.resetButton.alpha = 0.9;
                         }
                         completion:nil];
        self.magnifyingGlassImageView.hidden = NO;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                break;
            }
        }
        
        [self searchForTracksWithString:selectedTrack.artistName];
        self.searchBox.text = selectedTrack.artistName;
        [self updateVisibilityOfMagnifyingGlassAndResetButtons];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Artist Hack Button"];
    }
}

/*
 - (void) retrieveTracksForCategory:(NSString *)playlistName
 {
 Mixpanel *mixpanel = [Mixpanel sharedInstance];
 [mixpanel track:@"Searched Songs"];
 [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];
 
 self.songs = nil;
 [self.carousel reloadData];
 self.carousel.alpha = 1;
 self.loadingIndicator.alpha = 1;
 [self.loadingIndicator startAnimating];
 
 __weak YSSpotifySourceController *weakSelf = self;
 void (^callback)(NSArray*, NSError*) = ^(NSArray *songs, NSError *error) {
 //NSLog(@"Songs: %@", songs);
 if (songs) {
 weakSelf.songs = songs;
 weakSelf.carousel.currentItemIndex = 0;
 [weakSelf.carousel reloadData];
 
 if (songs.count == 0) {
 [self.loadingIndicator stopAnimating];
 
 NSLog(@"No Songs Returned For Search Query");
 
 double delay = 0.2;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
 });
 } else {
 NSLog(@"Returned Songs Successfully");
 [self.loadingIndicator stopAnimating];
 }
 } else if (error) {
 [self.loadingIndicator stopAnimating];
 
 if ([self internetIsNotReachable]) {
 double delay = 0.1;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
 });
 } else {
 NSLog(@"Error Returning Songs %@", error);
 [mixpanel track:@"Spotify Error - search (other)"];
 }
 }
 };
 
 [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForPlaylist:playlistName withCallback:callback];
 }
 */


@end
