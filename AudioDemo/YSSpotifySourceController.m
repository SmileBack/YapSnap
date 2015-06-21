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
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "SpotifyArtistFactory.h"
#import "UIViewController+MJPopupViewController.h"
#import "SearchArtistAlertView.h"
//#import "YTSearchSuggestionsViewController.h"

@interface YSSpotifySourceController () /*<YTSearchSuggestionsViewControllerDelegate>*/
@property (nonatomic, strong) NSArray *songs;
@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic, strong) NSString *alertViewString;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (strong, nonatomic) IBOutlet UIButton *resetButton;
@property (nonatomic, strong) NSArray *artists;
@property (nonatomic, strong) NSDictionary *typeToGenreMap;
@property (strong, nonatomic) UIButton *spotifyButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *carouselHeightConstraint;
@property (strong, nonatomic) IBOutlet UIButton *bottomButton;
@property (strong, nonatomic) UIButton *artistButton;
@property (strong, nonatomic) IBOutlet UIImageView *magnifyingGlassImageView;
@property (nonatomic, strong) NSString *artistNameString;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *carouselYConstraint;
//@property (strong, nonatomic) YTSearchSuggestionsViewController* searchSuggestionViewController;
@property (strong, nonatomic) UIButton *artistButtonHack;
@property (nonatomic, strong) NSString *lastShownPlaylist;
@property (nonatomic, strong) NSString *playlistOne;
@property (nonatomic, strong) NSString *playlistTwo;
@property (nonatomic, strong) NSString *playlistThree;
@property (nonatomic, strong) NSString *playlistFour;
@property (nonatomic, strong) NSString *playlistFive;
@property (nonatomic, strong) NSString *playlistSix;
@property (nonatomic, strong) NSString *playlistSeven;
@property (nonatomic, strong) NSString *playlistEight;

- (IBAction)didTapResetButton;
- (IBAction)didTapTopChartsButton:(id)sender;

@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Spotify Page"];

    [SpotifyAPI sharedApi]; //Activate to get access token
    
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
    CGFloat carouselHeight = 0.0;
    if (IS_IPHONE_4_SIZE) {
        carouselHeight = 140; // 69; 138*100
    } else if (IS_IPHONE_5_SIZE) {
        carouselHeight = 200; // 99; 198*100
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        carouselHeight = 290; // 144; (288*100) *1.5
    } else {
        carouselHeight = 240; // 119; (238*100) *1.172  279*117
    }
    self.carouselHeightConstraint.constant = carouselHeight;
    
    if (IS_IPHONE_6_SIZE) {
        self.carouselYConstraint.constant = 50;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.carouselYConstraint.constant = 60;
    }
    
    [self createArtistButtonHack];
}

- (void) createArtistButtonHack {
    self.artistButtonHack = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.artistButtonHack addTarget:self
               action:@selector(didTapArtistButtonHack)
     forControlEvents:UIControlEventTouchUpInside];
    self.artistButtonHack.frame = CGRectMake((self.view.bounds.size.width - self.carouselHeightConstraint.constant)/2, 340, self.carouselHeightConstraint.constant, 24.0);
    //self.artistButtonHack.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.artistButtonHack];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    [self hideAlbumBannerWithFadeAnimation:NO];
    self.bottomButton.hidden = NO;
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
                        [self hideAlbumBannerWithFadeAnimation:YES];
                        self.bottomButton.hidden = NO;
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
    [self resetUI];
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.searchBox becomeFirstResponder];
    });
}

- (IBAction)didTapTopChartsButton:(id)sender {
    [self resetBottomBannerUI];
    [self.view endEditing:YES];
    [self updateVisibilityOfMagnifyingGlassAndResetButtons];
    
    self.playlistOne = @"One";
    self.playlistTwo = @"Two";
    self.playlistThree = @"Three";
    self.playlistFour = @"Four";
    self.playlistFive = @"Five";
    self.playlistSix = @"Six";
    self.playlistSeven = @"Seven";
    
    if (!self.lastShownPlaylist) {
        NSLog(@"playlist one: %@", self.playlistOne);
        [self retrieveTracksForPlaylist:self.playlistOne];
        self.lastShownPlaylist = self.playlistOne;
        self.searchBox.text = self.playlistOne;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistOne]) {
        [self retrieveTracksForPlaylist:self.playlistTwo];
        self.lastShownPlaylist = self.playlistTwo;
        self.searchBox.text = self.playlistTwo;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistTwo]) {
        [self retrieveTracksForPlaylist:self.playlistThree];
        self.lastShownPlaylist = self.playlistThree;
        self.searchBox.text = self.playlistThree;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistThree]) {
        [self retrieveTracksForPlaylist:self.playlistFour];
        self.lastShownPlaylist = self.playlistFour;
        self.searchBox.text = self.playlistFour;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFour]) {
        [self retrieveTracksForPlaylist:self.playlistFive];
        self.lastShownPlaylist = self.playlistFive;
        self.searchBox.text = self.playlistFive;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFive]) {
        [self retrieveTracksForPlaylist:self.playlistSix];
        self.lastShownPlaylist = self.playlistSix;
        self.searchBox.text = self.playlistSix;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistSix]) {
        YSTrack *track = [YSTrack new];
        track.name = @"Home";
        track.spotifyID = @"Home";
        track.previewURL = @"Home";
        track.artistName = @"Home";
        track.albumName = @"Home";
        track.spotifyURL = @"Home";
        track.albumName = @"Home";
        track.imageURL = @"Home";
        
        self.songs = @[track];//[YSTrack tracksFromDictionaryArray:track inCategory:YES];
        self.carousel.currentItemIndex = 0;
        [self.carousel reloadData];
        
        self.lastShownPlaylist = self.playlistSeven;
    } else {
        [self retrieveTracksForPlaylist:self.playlistOne];
        self.lastShownPlaylist = self.playlistOne;
        self.searchBox.text = self.playlistOne;
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
    [self.searchBox setTintColor:[UIColor whiteColor]];
    self.searchBox.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    self.searchBox.delegate = self;
    [self.searchBox addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.searchBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type a phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
    
    self.searchBox.layer.cornerRadius=2.0f;
    self.searchBox.layer.masksToBounds=YES;
    self.searchBox.layer.borderColor=[[UIColor colorWithWhite:1.0 alpha:0.7]CGColor];
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
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            if (songs.count == 0) {
                [self.loadingIndicator stopAnimating];
                self.carousel.alpha = 0;
                
                NSLog(@"No Songs Returned For Search Query");
                
                double delay = 0.2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
                });
                
                double delay2 = 1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.searchBox becomeFirstResponder];
                });
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
                if (!self.didViewSpotifySongs) {
                    double delay = .7;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_VIEW_SPOTIFY_SONGS];
                    });
                }
            }
        } else if (error) {
            [self.loadingIndicator stopAnimating];
            self.carousel.alpha = 0;
            
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
    
    [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForSearchString:searchString withCallback:callback];
}

- (void) retrieveTracksForPlaylist:(NSString *)playlistName
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
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            
            if (songs.count == 0) {
                [self.loadingIndicator stopAnimating];
                self.carousel.alpha = 0;
                
                NSLog(@"No Songs Returned For Search Query");
                
                double delay = 0.2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
                });
                
                double delay2 = 1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.searchBox becomeFirstResponder];
                });
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
                if (!self.didViewSpotifySongs) {
                    double delay = .7;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_VIEW_SPOTIFY_SONGS];
                    });
                }
            }
        } else if (error) {
            [self.loadingIndicator stopAnimating];
            self.carousel.alpha = 0;
            
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
  
    [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForPlaylist:playlistName withCallback:callback];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"Textfield did begin editing");
    self.carousel.scrollEnabled = NO;
    self.carousel.alpha = 0;
    
    [self resetBottomBannerUI];
    
    /*
    self.searchSuggestionViewController = [[YTSearchSuggestionsViewController alloc] init];
    self.searchSuggestionViewController.searchSuggestionsDelegate = self;
    [self addChildViewController:self.searchSuggestionViewController];
    [self.view addSubview:self.searchSuggestionViewController.view];
    [self.searchSuggestionViewController didMoveToParentViewController:self];
    [self.searchSuggestionViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view": self.searchSuggestionViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[search][view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"search": self.searchBox,
                                                                                @"view": self.searchSuggestionViewController.view}]];
     */
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"Textfield did end editing");
    [self setUserInteractionEnabled:YES];
    /*
    [self.searchSuggestionViewController.view removeFromSuperview];
    [self.searchSuggestionViewController removeFromParentViewController];
    self.searchSuggestionViewController = nil;
     */
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
    }
}

/*
#pragma mark - YTSearchSuggestionsViewControllerDelegate

- (void)didSelectSearchSuggestion:(YTSpotifyCategory *)suggestion {
    self.searchBox.text = suggestion.displayName;
    [self.searchBox resignFirstResponder];
    [self search:suggestion.displayName inCategory:suggestion];
}
*/

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
        trackView.songNameLabel.textColor = [UIColor whiteColor];
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
        trackView.artistButton.backgroundColor = THEME_DARK_BLUE_COLOR;
        [trackView.artistButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:12]];
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

        
        // ALBUM BANNER LABEL
        trackView.bannerLabel = [[UILabel alloc]initWithFrame:
                                               CGRectMake(2, 2, carouselHeight-4, 42)];
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, 41.0f, trackView.bannerLabel.frame.size.width, 2.0f);
        bottomBorder.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
        [trackView.bannerLabel.layer addSublayer:bottomBorder];
        
        trackView.bannerLabel.backgroundColor = THEME_RED_COLOR;
        trackView.bannerLabel.textAlignment = NSTextAlignmentCenter;
        trackView.bannerLabel.textColor = [UIColor whiteColor];
        trackView.bannerLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        [trackView addSubview:trackView.bannerLabel];
        
        trackView.bannerLabel.alpha = 0;
        
        trackView.imageView.layer.borderWidth = 2;
        trackView.imageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
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
    
    trackView.songNameLabel.text = track.name;
    trackView.spotifySongID = track.spotifyID;
    trackView.spotifyURL = track.spotifyURL;
    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
    CGSize stringsize = [[NSString stringWithFormat:@"by %@", track.artistName] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:12]}];
    if ((stringsize.width + 20) > self.carouselHeightConstraint.constant) {
        stringsize.width = self.carouselHeightConstraint.constant-24;
    }
    [trackView.artistButton setFrame:CGRectMake((self.carouselHeightConstraint.constant-stringsize.width-20)/2, self.carouselHeightConstraint.constant + 35, stringsize.width+20, stringsize.height + 8)];
    
    return trackView;
}

- (void)didTapCarousel:(UITapGestureRecognizer*)tap {
    [self showBannerWithText:@"Hold To Play" temporary:YES];
}

- (void) showBannerWithText:(NSString*)text temporary:(BOOL)temporary {
    SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
    trackView.bannerLabel.text = text;
    trackView.bannerLabel.alpha = 1;
    
    if (temporary) {
        // Hide Label shortly after showing it
        double delay = 2.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 trackView.bannerLabel.alpha = 0;
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_SONG_VERSION_ONE];
    
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_SONG_VERSION_TWO];
    
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
/*
- (void) tappedArtistButton:(UIButton *)button
{
    NSLog(@"Tapped Artist Button");
    if (!self.didViewSearchArtistPopup) {
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
            SearchArtistAlertView *alertView = [[SearchArtistAlertView alloc] initWithArtistName:selectedTrack.artistName andDelegate:self];
            self.artistNameString = selectedTrack.artistName;
            [alertView show];
        }
    } else {
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
            NSLog(@"Artist: %@", selectedTrack.artistName);
            NSLog(@"Song: %@", selectedTrack.name);
            [self search:selectedTrack.artistName inCategory:nil];
            self.searchBox.text = selectedTrack.artistName;
            [self updateVisibilityOfMagnifyingGlassAndResetButtons];
        }
    }
}
*/
- (void)didTapArtistButtonHack {
    
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
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    NSLog(@"DidEndScrollingAnimation");
    self.artistButtonHack.frame = CGRectMake((self.view.bounds.size.width - self.carouselHeightConstraint.constant)/2, 340, self.carouselHeightConstraint.constant, 24.0);
    
    //self.artistButtonHack.backgroundColor = [UIColor redColor];
    
    SpotifyTrackView* trackView = (SpotifyTrackView*)[self.carousel itemViewAtIndex:self.carousel.currentItemIndex];
    YSTrack *selectedTrack = nil;
    for (YSTrack *track in self.songs) {
        if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
            selectedTrack = track;
            break;
        }
    }
    
    CGSize stringsize = [[NSString stringWithFormat:@"by %@", selectedTrack.artistName] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:12]}];
    
    if ((stringsize.width + 20) > self.carouselHeightConstraint.constant) {
        stringsize.width = self.carouselHeightConstraint.constant-24;
    }
    [self.artistButtonHack setFrame:CGRectMake((self.view.bounds.size.width - (stringsize.width+20))/2, 336, stringsize.width+20, stringsize.height + 8)];
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

- (BOOL) didTapSongVersionOneForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_SONG_VERSION_ONE];
}

- (BOOL) didTapSongVersionTwoForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_SONG_VERSION_TWO];
}

- (BOOL) didOpenYapForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
}

- (BOOL) didScrollCarousel
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:SCROLLED_CAROUSEL];
}

- (BOOL) didViewSpotifySongs
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_VIEW_SPOTIFY_SONGS];
}

- (BOOL) didViewSearchArtistPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_VIEW_SEARCH_ARTIST_POPUP];
}

- (void) hideResetButton {
    self.resetButton.alpha = 0;
}

- (void) resetUI {
    self.songs = nil;

    [UIView animateWithDuration:.05
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Type a phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
                         self.searchBox.attributedPlaceholder = string;
                         
                         self.carousel.alpha = 0;
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

#pragma mark - Control Center Stuff

- (void) showRandomPickAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Here's a Random Artist"
                                                    message:@"Tap the shuffle button to explore\nmore artists."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) updateVisibilityOfMagnifyingGlassAndResetButtons {
    CGSize stringsize = [[NSString stringWithFormat:@"%@", self.searchBox.text] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:18]}];
    NSLog(@"STRING WIDTH %f", stringsize.width);
    if (stringsize.width > 210) {
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
    if ([alertView isKindOfClass:[SearchArtistAlertView class]]) {
        if (buttonIndex == 1) {
            [self searchForTracksWithString:self.artistNameString];
            self.searchBox.text = self.artistNameString;
            [self updateVisibilityOfMagnifyingGlassAndResetButtons];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_VIEW_SEARCH_ARTIST_POPUP];
        }
    }
}

@end
