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
#import "SpotifyTrackFactory.h"
#import "UIViewController+MJPopupViewController.h"
#import "SearchArtistAlertView.h"
#import "TopChartsPopupViewController.h"

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
@property (strong, nonatomic) TopChartsPopupViewController *topChartsPopupVC;
@property (nonatomic, strong) NSArray *tracks;

@property (nonatomic, strong) NSString *playlistOne;
@property (nonatomic, strong) NSString *playlistTwo;
@property (nonatomic, strong) NSString *playlistThree;
@property (nonatomic, strong) NSString *playlistFour;
@property (nonatomic, strong) NSString *playlistFive;
@property (nonatomic, strong) NSString *playlistSix;
@property (nonatomic, strong) NSString *playlistSeven;
@property (nonatomic, strong) NSString *playlistEight;
@property (nonatomic, strong) NSString *playlistNine;
@property (nonatomic, strong) NSString *playlistTen;
@property (nonatomic, strong) NSString *playlistEleven;
@property (nonatomic, strong) NSString *playlistTwelve;
@property (nonatomic, strong) NSString *playlistThirteen;
@property (nonatomic, strong) NSString *playlistFourteen;
@property (nonatomic, strong) NSString *playlistFifteen;
@property (nonatomic, strong) NSString *playlistSixteen;
@property (nonatomic, strong) NSString *playlistSeventeen;
@property (nonatomic, strong) NSString *playlistEighteen;
@property (nonatomic, strong) NSString *playlistNineteen;
@property (nonatomic, strong) NSString *playlistTwenty;
@property (nonatomic, strong) NSString *playlistTwentyOne;

- (IBAction)didTapResetButton;
- (IBAction)didTapTopChartsButton;

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
    
    [self displaySuggestedSongs];
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
    
    [center addObserverForName:DISMISS_TOP_CHARTS_POPUP_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Dismiss Welcome Popup");
                        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
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

- (IBAction)didTapTopChartsButton {
    if (!self.didSeeTopChartsPopup) {
        [self showTopChartsPopup];
    }
    
    [self resetBottomBannerUI];
    [self.view endEditing:YES];
    
    [self declarePlaylists];
    
    [self loadAppropriatePlaylist];
    
    [self updateVisibilityOfMagnifyingGlassAndResetButtons];
}

- (void) declarePlaylists {
    
    self.playlistOne = @"Top 100 Tracks";
    self.playlistTwo = @"Today's Top Hits";
    self.playlistThree = @"Top Viral Tracks";
    self.playlistFour = @"New Music Tuesday";
    self.playlistFive = @"Five";
    self.playlistSix = @"Six";
    self.playlistSeven = @"Seven";
    
/*
    self.playlistOne = @"Comedy New Releases";
    self.playlistTwo = @"Comedy Top Tracks";
    self.playlistThree = @"The Laugh List";
    self.playlistFour = @"British Humour";
    self.playlistFive = @"Quirck It";
    self.playlistSix = @"Funny Things About Football";
    self.playlistSeven = @"Monty Python Emporium";
    self.playlistEight = @"Ladies Night";
    self.playlistNine = @"20 Questions";
    self.playlistTen = @"Animal Humor";
    self.playlistEleven = @"Music Jokes";
    self.playlistTwelve = @"Dating Issues";
    self.playlistThirteen = @"Comedy Goes Country";
    self.playlistFourteen = @"Unsolicited Advice";
    self.playlistFifteen = @"Office Offensive";
    self.playlistSixteen = @"Love & Marriage";
    self.playlistSeventeen = @"The Interwebs";
    self.playlistEighteen = @"Lights, Camera, Comedy!";
    self.playlistNineteen = @"Louis CK | Collected";
    self.playlistTwenty = @"[Family]";
    self.playlistTwentyOne = @"Comedy Top Trackss";
*/
}

- (void) loadAppropriatePlaylist {
    if (!self.lastShownPlaylist) {
        [self retrieveTracksForPlaylist:self.playlistOne];
        self.lastShownPlaylist = self.playlistOne;
        self.searchBox.text = self.playlistOne;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistOne] && self.playlistTwo) {
        [self retrieveTracksForPlaylist:self.playlistTwo];
        self.lastShownPlaylist = self.playlistTwo;
        self.searchBox.text = self.playlistTwo;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistTwo] && self.playlistThree) {
        [self retrieveTracksForPlaylist:self.playlistThree];
        self.lastShownPlaylist = self.playlistThree;
        self.searchBox.text = self.playlistThree;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistThree] && self.playlistFour) {
        [self retrieveTracksForPlaylist:self.playlistFour];
        self.lastShownPlaylist = self.playlistFour;
        self.searchBox.text = self.playlistFour;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFour] && self.playlistFive) {
        [self retrieveTracksForPlaylist:self.playlistFive];
        self.lastShownPlaylist = self.playlistFive;
        self.searchBox.text = self.playlistFive;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFive] && self.playlistSix) {
        [self retrieveTracksForPlaylist:self.playlistSix];
        self.lastShownPlaylist = self.playlistSix;
        self.searchBox.text = self.playlistSix;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistSix] && self.playlistSeven) {
        [self retrieveTracksForPlaylist:self.playlistSeven];
        self.lastShownPlaylist = self.playlistSeven;
        self.searchBox.text = self.playlistSeven;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistSeven] && self.playlistEight) {
        [self retrieveTracksForPlaylist:self.playlistEight];
        self.lastShownPlaylist = self.playlistEight;
        self.searchBox.text = self.playlistEight;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistEight] && self.playlistNine) {
        [self retrieveTracksForPlaylist:self.playlistNine];
        self.lastShownPlaylist = self.playlistNine;
        self.searchBox.text = self.playlistNine;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistNine] && self.playlistTen) {
        [self retrieveTracksForPlaylist:self.playlistTen];
        self.lastShownPlaylist = self.playlistTen;
        self.searchBox.text = self.playlistTen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistTen] && self.playlistEleven) {
        [self retrieveTracksForPlaylist:self.playlistEleven];
        self.lastShownPlaylist = self.playlistEleven;
        self.searchBox.text = self.playlistEleven;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistEleven] && self.playlistTwelve) {
        [self retrieveTracksForPlaylist:self.playlistTwelve];
        self.lastShownPlaylist = self.playlistTwelve;
        self.searchBox.text = self.playlistTwelve;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistTwelve] && self.playlistThirteen) {
        [self retrieveTracksForPlaylist:self.playlistThirteen];
        self.lastShownPlaylist = self.playlistThirteen;
        self.searchBox.text = self.playlistThirteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistThirteen] && self.playlistFourteen) {
        [self retrieveTracksForPlaylist:self.playlistFourteen];
        self.lastShownPlaylist = self.playlistFourteen;
        self.searchBox.text = self.playlistFourteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFourteen] && self.playlistFifteen) {
        [self retrieveTracksForPlaylist:self.playlistFifteen];
        self.lastShownPlaylist = self.playlistFifteen;
        self.searchBox.text = self.playlistFifteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistFifteen] && self.playlistSixteen) {
        [self retrieveTracksForPlaylist:self.playlistSixteen];
        self.lastShownPlaylist = self.playlistSixteen;
        self.searchBox.text = self.playlistSixteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistSixteen] && self.playlistSeventeen) {
        [self retrieveTracksForPlaylist:self.playlistSeventeen];
        self.lastShownPlaylist = self.playlistSeventeen;
        self.searchBox.text = self.playlistSeventeen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistSeventeen] && self.playlistEighteen) {
        [self retrieveTracksForPlaylist:self.playlistEighteen];
        self.lastShownPlaylist = self.playlistEighteen;
        self.searchBox.text = self.playlistEighteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistEighteen] && self.playlistNineteen) {
        [self retrieveTracksForPlaylist:self.playlistNineteen];
        self.lastShownPlaylist = self.playlistNineteen;
        self.searchBox.text = self.playlistNineteen;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistNineteen] && self.playlistTwenty) {
        [self retrieveTracksForPlaylist:self.playlistTwenty];
        self.lastShownPlaylist = self.playlistTwenty;
        self.searchBox.text = self.playlistTwenty;
    } else if ([self.lastShownPlaylist isEqualToString:self.playlistTwenty] && self.playlistTwentyOne) {
        [self retrieveTracksForPlaylist:self.playlistTwentyOne];
        self.lastShownPlaylist = self.playlistTwentyOne;
        self.searchBox.text = self.playlistTwentyOne;
    } else{
        [self retrieveTracksForPlaylist:self.playlistOne];
        self.lastShownPlaylist = self.playlistOne;
        self.searchBox.text = self.playlistOne;
    }
    
    /*
     YSTrack *track = [YSTrack new];
     track.name = @"Home";
     track.spotifyID = @"Home";
     track.previewURL = @"Home";
     track.artistName = @"Home";
     track.albumName = @"Home";
     track.spotifyURL = @"Home";
     track.imageURL = @"Home";
     self.songs = @[track];//[YSTrack tracksFromDictionaryArray:track inCategory:YES];
     self.carousel.currentItemIndex = 0;
     [self.carousel reloadData];
     */
}

-(void) displaySuggestedSongs {
    if (!self.tracks || self.tracks.count < 5) {
        self.tracks = [SpotifyTrackFactory tracks];
    }
    
    NSArray *randomlySelectedTrack = [self.tracks objectAtIndex: arc4random() % [self.tracks count]];
    
    self.songs = @[randomlySelectedTrack];
    self.carousel.currentItemIndex = 0;
    [self.carousel reloadData];
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
    self.searchBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
    
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
        NSLog(@"Songs: %@", songs);
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
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
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
                /*
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Something Went Wrong! Try Again."];
                });
                */
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
        
        // For Onboarding:
        if (!self.didPlaySongForFirstTime) {
            trackView.bannerLabel.alpha = 1;
            trackView.bannerLabel.text = @"Hold To Play";
        } else {
            trackView.bannerLabel.alpha = 0;
        }
        
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

- (BOOL) didSeeTopChartsPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SEE_TOP_CHARTS_POPUP_KEY];
}

- (BOOL) didPlaySongForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_PLAY_SONG_FOR_FIRST_TIME_KEY];
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
                         NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Type any phrase or song" attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35] }];
                         self.searchBox.attributedPlaceholder = string;
                         
                         self.carousel.alpha = 0;
                         [self hideResetButton];
                         self.loadingIndicator.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         self.searchBox.text = @"";
                     }];
}

- (void) showTopChartsPopup {
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.topChartsPopupVC = [[TopChartsPopupViewController alloc] initWithNibName:@"TopChartsPopupViewController" bundle:nil];
        [self presentPopupViewController:self.topChartsPopupVC animationType:MJPopupViewAnimationFade];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_SEE_TOP_CHARTS_POPUP_KEY];
    });
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
        }
    }
}

@end
