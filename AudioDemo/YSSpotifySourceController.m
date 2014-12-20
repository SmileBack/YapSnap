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


@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;
@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupSearchBox];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Search box stuff
- (void) setupSearchBox
{
//    double delay = 0.6;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.searchBox becomeFirstResponder];
//    });
    
    self.searchBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    [self.searchBox setTintColor:[UIColor whiteColor]];
    self.searchBox.font = [UIFont fontWithName:@"Futura-Medium" size:30];
    self.searchBox.delegate = self;
    
    /*self.searchBox.attributedPlaceholder =
     [[NSAttributedString alloc] initWithString:@"Type an artist, song, or album"
     attributes:@{
     NSForegroundColorAttributeName: [UIColor lightGrayColor],
     NSFontAttributeName : [UIFont fontWithName:@"Futura-Medium" size:17.0]
     }
     ];
     */
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self search:self.searchBox.text];
    [self.view endEditing:YES];
    
    return YES;
}

- (void) search:(NSString *)search
{
    __weak YSSpotifySourceController *weakSelf = self;
    [[SpotifyAPI sharedApi] searchSongs:search withCallback:^(NSArray *songs, NSError *error) {
        NSLog(@"in callback");
        if (songs) {
            weakSelf.songs = songs;
            [weakSelf.carousel reloadData];
        } else if (error) {
            // TODO do something with error
        }
    }];
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
    
    NSLog(@"getting view for %ld", (long)index);
    
    CGRect frame = CGRectMake(0, 0, 200, 200);
    UIView *trackView = [[UIView alloc] initWithFrame:frame];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    [imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
    [trackView addSubview:imageView];
    
    UILabel *label = [[UILabel alloc]initWithFrame:
                      CGRectMake(0, 200, 200, 25)];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = track.name;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    [trackView addSubview:label];
    
    UIButton *spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    spotifyButton.frame = CGRectMake(160, 5, 35, 35);
    [spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
    [spotifyButton addTarget:self action:@selector(listenOnSpotify) forControlEvents:UIControlEventTouchUpInside];
    [trackView addSubview:spotifyButton];
    
    return trackView;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    
    YSTrack *song = self.songs[index];
    NSLog(@"Song name: %@", song.name);
    NSLog(@"Spotify ID: %@", song.spotifyID);
    NSLog(@"Spotify URL: %@", song.spotifyURL);
    NSLog(@"Preview URL: %@", song.previewURL);
    NSLog(@"Album Name: %@", song.albumName);
    NSLog(@"Artist Name: %@", song.artistName);
    NSLog(@"Image URL: %@", song.imageURL);
    
    
    // LISTEN TO PREVIEW URL
    
    //NSURL *url = [NSURL URLWithString:@"https://p.scdn.co/mp3-preview/5a9da4605959338f2363079af5895e74fba8a479"];
    
    // LISTEN TO SONG ON SPOTIFY - how can we send user to spotify if he/she has it installed?
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:song.spotifyURL]];
    
    
    // SEND YAP TO BACKEND - backend needs to be implemented
    /*
     [[API sharedAPI] sendSong:song withCallback:^(BOOL success, NSError *error) {
     if (success) {
     NSLog(@"IT WORKED!!!!");
     } else {
     NSLog(@"it didnt work: %@", error);
     }
     }];
     */
}


#pragma mark - Implement public audio methods
- (void) startAudioCapture
{
    // Play Spotify Track here
}

@end
