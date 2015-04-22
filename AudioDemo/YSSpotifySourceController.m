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

#define NO_SONGS_TO_PLAY_ALERT @"NoSongs"

@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIImageView *musicIcon;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic, strong) NSString *alertViewString;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) float carouselHeight;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (strong, nonatomic) IBOutlet UIButton *smallMusicIcon;

- (IBAction)didTapSmallMusicButton;

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
    
    [self setupNotifications];
    
    UITapGestureRecognizer *tappedMusicIconImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedMusicIconImage)];
    tappedMusicIconImage.numberOfTapsRequired = 1;
    [self.musicIcon addGestureRecognizer:tappedMusicIconImage];
    
    UITapGestureRecognizer *tappedSpotifyView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedSpotifyView)];
    tappedSpotifyView.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tappedSpotifyView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.playerAlreadyStartedPlayingForThisSong = NO;
    NSLog(@"Set playerAlreadyStartedPlayingForThisSong to FALSE");
    
    if (self.didOpenYapForFirstTime && !self.didViewMusicNoteNotification && !self.didTapLargeMusicButtonForFirstTime && !self.didTapSmallMusicButtonForFirstTime) {
        [[YTNotifications sharedNotifications] showNotificationText:@"Tap Music Note ;)"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:VIEWED_MUSIC_NOTE_NOTIFICATION];
    }
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:TAPPED_PROGRESS_VIEW_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Tapped Progress View");
                        [self.searchBox becomeFirstResponder];
                    }];
}
 
- (void)tappedMusicIconImage {
    NSLog(@"Tapped Music Icon Image");
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Music Icon"];
    /*
    if (self.searchBox.isFirstResponder) {
        self.searchBox.text = [self.searchBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self.searchBox.text length] == 0) {
            [self.view endEditing:YES];
            self.musicIcon.hidden = NO; // REMOVE
        } else {
            [self search:self.searchBox.text];
            [self.view endEditing:YES];
            [self setBackgroundColorForSearchBox];
        }
    } else {
        NSLog(@"Search Box Is Not First Responder");
        [self.searchBox becomeFirstResponder];
    }
    */
    [self searchRandomArtist];
    if (!self.didTapLargeMusicButtonForFirstTime) {
        [[YTNotifications sharedNotifications] showNotificationText:@"Random Pick!"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_LARGE_MUSIC_BUTTON];
    }
}

- (void)tappedSpotifyView {
    NSLog(@"Tapped Spotify View");
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Spotify View"];
    if (self.searchBox.isFirstResponder) {
        self.searchBox.text = [self.searchBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self.searchBox.text length] == 0) {
            [self.view endEditing:YES];
            self.musicIcon.hidden = NO; // REMOVE
        } else {
            [self search:self.searchBox.text];
            [self.view endEditing:YES];
            [self setBackgroundColorForSearchBox];
        }
    } else {
        NSLog(@"Search Box Is Not First Responder");
        [self.searchBox becomeFirstResponder];
    }
}

- (void) setBackgroundColorForSearchBox {
    //Background text color
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.searchBox.text];
    [attributedString addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.15] range:NSMakeRange(0, self.searchBox.text.length)];
    self.searchBox.attributedText = attributedString;
}

- (IBAction) didTapSmallMusicButton {
    [self searchRandomArtist];
    if (!self.didTapSmallMusicButtonForFirstTime) {
        [[YTNotifications sharedNotifications] showNotificationText:@"Random Pick!"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_SMALL_MUSIC_BUTTON];
    }
}

- (void) searchRandomArtist {
    NSArray *artists = [[NSArray alloc] initWithObjects:@"Maroon 5", @"Wiz Khalifa", @"Drake", @"Ed Sheeran", @"Sam Smith", @"All Time Low", @"Meghan Trainor", @"Ellie Goulding", @"Ariana Grande", @"Nicki Minaj",@"Kendrick Lamar", @"Rihanna", @"Mark Ronson", @"Wiz Khalifa", @"Nick Jonas", @"Bruno Mars",@"WALK THE MOON", @"Fall Out Boy", @"Imagine Dragons", @"Fetty Wap", @"Sam Hunt", @"Flo Rida", @"Jason Derulo", @"Beyonce", @"Florida Georgia Line", @"Katy Perry", @"Big Sean", @"Luke Bryan",@"Charlie Puth", @"Wale", @"Sia", @"Tove Lo", @"Kelly Clarkson", @"Hozier",@"One Direction", @"Chris Brown", @"Eminem", @"Zac Brown Band", @"Darius Rucker", @"Ludacris",@"Rae Sremmurd", @"J. Cole", @"Blake Shelton", @"Jason Aldean", @"Kanye West", @"Iggy Azalea",@"Eric Church", @"Natalie La Rose", @"Selena Gomez", @"Pitbull", @"Ne-Yo", @"Lee Brice",@"Vance Joy", @"George Ezra", @"Calvin Harris", @"Trey Songz", @"Andy Grammer", @"Lord Huron", @"Carrie Underwood", @"Mumford & Sons", @"Justin Bieber", @"David Guetta", @"Kidz Bop Kids", @"Fifth Harmony", @"Cole Swindell", @"Tyga", @"Little Big Town", @"OneRepublic", @"Miranda Lambert",@"Usher", @"Echosmith", @"Jeremih", @"Thomas Rhett", @"Zedd", @"Dierks Bentley", @"Justin Timberlake", @"Kid Ink", @"Brian Wilson", @"Madonna", @"Omarion", @"AC/DC", @"Kenny Chesney", @"Tim McGraw", @"Death Cab For Cutie", @"Romeo Santos", @"Kid Rock", @"Pharrell Williams", @"Twenty One Pilots", @"DJ Snake", @"John Legend", @"Three Days Grace", @"Adele", @"Michael Jackson", @"Shawn Mendes", @"Led Zeppelin", @"Matt And Kim", @"Matt And Kim", @"Billy Currington", @"Paul McCartney", @"U2", @"Coldplay", @"Avicci", nil];
    
    NSString *randomlySelectedArtist = [artists objectAtIndex: arc4random() % [artists count]];
    
    NSLog(@"string: %@", randomlySelectedArtist);
    
    [self search:randomlySelectedArtist];
    self.searchBox.text = randomlySelectedArtist;
    [self setBackgroundColorForSearchBox];
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
    self.searchBox.font = [UIFont fontWithName:@"Futura-Medium" size:28];
    self.searchBox.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Remove extra space at end of string
    self.searchBox.text = [self.searchBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([self.searchBox.text length] == 0) {
        NSLog(@"Searched Empty String");
        [self.view endEditing:YES];
        self.musicIcon.hidden = NO; // REMOVE
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search for a Song"
                                                        message:@"To send a song snippet, type the name of an artist, song, or album above."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        [self.view endEditing:YES];
        [self search:self.searchBox.text];
        [self setBackgroundColorForSearchBox];
    }
    
    return YES;
}

- (void) search:(NSString *)search
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched Songs"];
    [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];
    
    self.songs = nil;
    [self.carousel reloadData];
    self.musicIcon.hidden = YES;
    // UNHIDE CAROUSEL!
    self.carousel.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    __weak YSSpotifySourceController *weakSelf = self;
    [[SpotifyAPI sharedApi] searchSongs:search withCallback:^(NSArray *songs, NSError *error) {
        if (songs) {
            weakSelf.songs = songs;
            weakSelf.carousel.currentItemIndex = 0;
            [weakSelf.carousel reloadData];
            if (songs.count == 0) {
                [self.loadingIndicator stopAnimating];
                self.musicIcon.hidden = NO;
                self.carousel.hidden = YES;
                
                NSLog(@"No Songs Returned For Search Query");
                
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
                });
            } else {
                NSLog(@"Returned Songs Successfully");
                [self.loadingIndicator stopAnimating];
                self.smallMusicIcon.hidden = NO;
            }
        } else if (error) {
            [self.loadingIndicator stopAnimating];
            self.musicIcon.hidden = NO;
            self.carousel.hidden = YES;
            self.smallMusicIcon.hidden = YES;
            
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
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"Textfield did begin editing");
    self.carousel.scrollEnabled = NO;
    self.musicIcon.hidden = YES; // REMOVE
    self.smallMusicIcon.hidden = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"Textfield did end editing");
    self.carousel.scrollEnabled = YES;
}

#pragma mark - iCarousel Stuff
#pragma mark iCarousel
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
        
        if (IS_IPHONE_4_SIZE) {
            self.carouselHeight = 140; // 69; 138*100
        } else if (IS_IPHONE_5_SIZE) {
            self.carouselHeight = 200; // 99; 198*100
        } else if (IS_IPHONE_6_PLUS_SIZE) {
            self.carouselHeight = 290; // 144; (288*100) *1.5
        } else {
            self.carouselHeight = 240; // 119; (238*100) *1.172  279*117
        }

        CGRect frame = CGRectMake(0, 0, self.carouselHeight, self.carouselHeight);
        trackView = [[SpotifyTrackView alloc] initWithFrame:frame];

        trackView.imageView = [[UIImageView alloc] initWithFrame:frame];
        [trackView addSubview:trackView.imageView];
        
        trackView.label = [[UILabel alloc]initWithFrame:
                           CGRectMake(0, self.carouselHeight+4, self.carouselHeight, 25)];
        [trackView addSubview:trackView.label];
         
        trackView.albumImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.albumImageButton.frame = CGRectMake(0, 0, self.carouselHeight, self.carouselHeight);
        [trackView.albumImageButton setImage:nil forState:UIControlStateNormal];
        [trackView addSubview:trackView.albumImageButton];
        
        trackView.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.spotifyButton.frame = CGRectMake(self.carouselHeight-40, 5, 35, 35);
        [trackView.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
        [trackView addSubview:trackView.spotifyButton];
        
        if (IS_IPHONE_6_PLUS_SIZE) {
            trackView.songVersionBackground = [[UIView alloc]initWithFrame:
                                           CGRectMake(0, self.carouselHeight-26, self.carouselHeight, 26)];
        } else if (IS_IPHONE_6_SIZE) {
            trackView.songVersionBackground = [[UIView alloc]initWithFrame:
                                                   CGRectMake(0, self.carouselHeight-22, self.carouselHeight, 22)];
        } else {
            trackView.songVersionBackground = [[UIView alloc]initWithFrame:
                                               CGRectMake(0, self.carouselHeight-18, self.carouselHeight, 18)];
        }
        trackView.songVersionBackground.backgroundColor = THEME_BACKGROUND_COLOR;
        [trackView addSubview:trackView.songVersionBackground];
        
        trackView.songVersionOneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.songVersionOneButton.frame = CGRectMake(0, self.carouselHeight-50, self.carouselHeight/2 - 1, 50);
        [trackView.songVersionOneButton addTarget:self action:@selector(tappedSongVersionOneButton:) forControlEvents:UIControlEventTouchUpInside];
        [trackView addSubview:trackView.songVersionOneButton];
        
        trackView.songVersionTwoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        trackView.songVersionTwoButton.frame = CGRectMake(self.carouselHeight/2 + 1, self.carouselHeight-50, self.carouselHeight/2 - 1, 50);
        [trackView.songVersionTwoButton addTarget:self action:@selector(tappedSongVersionTwoButton:) forControlEvents:UIControlEventTouchUpInside];
        [trackView addSubview:trackView.songVersionTwoButton];
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
    
    trackView.songVersionOneButton.hidden = YES;
    trackView.songVersionTwoButton.hidden = YES;
    trackView.songVersionBackground.hidden = YES;
    
    // Set seconds to fast forward to 0
    track.secondsToFastForward = [NSNumber numberWithInt:0];

    if (track.imageURL) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
    } else {
        trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
    }
    [trackView.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.05]];

    // Needed so the Spotify button can work
    trackView.spotifySongID = track.spotifyID;
    trackView.spotifyURL = track.spotifyURL;
    
    trackView.label.textColor = [UIColor whiteColor];
    trackView.label.backgroundColor = [UIColor clearColor];
    trackView.label.text = track.name;
    trackView.label.textAlignment = NSTextAlignmentCenter;
    CGFloat size = IS_IPHONE_4_SIZE ? 14 : 18;
    trackView.label.font = [UIFont fontWithName:@"Futura-Medium" size:size];
    
    [trackView.spotifyButton addTarget:self action:@selector(confirmOpenInSpotify:) forControlEvents:UIControlEventTouchUpInside];
    [trackView.albumImageButton addTarget:self action:@selector(tappedAlbumImage:) forControlEvents:UIControlEventTouchUpInside];
    
    return trackView;
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
    
    if (!self.didTapSongVersionOneForFirstTime) {
        [[YTNotifications sharedNotifications] showSongVersionText:@"Version # 1"];
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
                break;
            }
        }
        selectedTrack.secondsToFastForward = [NSNumber numberWithInt:17];
    }
    
    if (!self.didTapSongVersionTwoForFirstTime) {
        [[YTNotifications sharedNotifications] showSongVersionText:@"Version # 2"];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_SONG_VERSION_TWO];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version Two"];
}

- (void) confirmOpenInSpotify:(UIButton *)button
{
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

- (void) tappedAlbumImage:(UIButton *)button
{
    NSLog(@"Tapped Album Image");
    
    if ([self.searchBox isFirstResponder])
    {
        [self.view endEditing:YES];
        self.smallMusicIcon.hidden = NO;
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
            
            if (!selectedTrack.songVersionButtonsAreShowing) {
                trackView.songVersionOneButton.hidden = NO;
                trackView.songVersionTwoButton.hidden = NO;
                trackView.songVersionBackground.hidden = NO;
                selectedTrack.songVersionButtonsAreShowing = YES;
            } else {
                trackView.songVersionOneButton.hidden = YES;
                trackView.songVersionTwoButton.hidden = YES;
                trackView.songVersionBackground.hidden = YES;
                selectedTrack.songVersionButtonsAreShowing = NO;
            }
        }
        
        if (!self.didTapAlbumCoverForFirstTime) {
            double delay = 0.1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:@"Hold Red Button"];
            });
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_ALBUM_COVER];
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

- (void) stopAudioCapture:(float)elapsedTime
{
    [self.player stop];
    [self enableUserInteraction]; // This is most likely redundant, but putting it here anyway just in case
}

- (void) enableUserInteraction
{
    [self.carousel setUserInteractionEnabled:YES];
    self.searchBox.enabled = YES;
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

    [self enableUserInteraction];
    [audioPlayer stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_UNEXPECTED_ERROR_NOTIFICATION object:nil];
    
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
            [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:self];
            YSTrack *track = self.songs[self.carousel.currentItemIndex];
            if (track.secondsToFastForward.intValue > 0) {
                [audioPlayer seekToTime:track.secondsToFastForward.intValue];
            }
            // set self.playerAlreadyStartedPlayingForThisSong to True!
            self.playerAlreadyStartedPlayingForThisSong = YES;
            NSLog(@"Set playerAlreadyStartedPlayingForThisSong to TRUE");
        }
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
        [[NSNotificationCenter defaultCenter] postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION object:nil];
        [self enableUserInteraction];
        
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
    
    if (state == STKAudioPlayerStateBuffering && previousState == STKAudioPlayerStatePlaying) {
        NSLog(@"state changed from playing to buffering");
        //[audioPlayer stop];
        //[[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_LOST_CONNECTION_NOTIFICATION object:nil];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search for a Song"
                                                        message:@"To send a song snippet, type the name of an artist, song, or album above."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        self.alertViewString = NO_SONGS_TO_PLAY_ALERT;
        [alert show];
        return NO;
    } else {
        //Disable User Interactions
        [self.carousel setUserInteractionEnabled:NO];
        self.searchBox.enabled = NO;
        
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
            [self enableUserInteraction];
            //THE FOLLOWING LINES STOP THE LOADING SPINNER
            double delay = 0.2;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION object:nil];
            });
            return NO;
        } else {
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            //NSLog(@"Volume: %f", volume);
            if (volume <= 0.125) {
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showVolumeText:@"Turn Up The Volume!"];
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"Volume Notification - Spotify"];
                });
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([NO_SONGS_TO_PLAY_ALERT isEqualToString:self.alertViewString]) {
        double delay = 0.4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.searchBox becomeFirstResponder];
        });
    }
}

- (BOOL) didTapAlbumCoverForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_ALBUM_COVER];
}

- (BOOL) didTapSongVersionOneForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_SONG_VERSION_ONE];
}

- (BOOL) didTapSongVersionTwoForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_SONG_VERSION_TWO];
}

- (BOOL) didTapLargeMusicButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_LARGE_MUSIC_BUTTON];
}

- (BOOL) didTapSmallMusicButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_SMALL_MUSIC_BUTTON];
}

- (BOOL) didOpenYapForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
}

- (BOOL) didViewMusicNoteNotification
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:VIEWED_MUSIC_NOTE_NOTIFICATION];
}

@end
