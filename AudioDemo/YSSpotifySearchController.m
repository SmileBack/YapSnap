//
//  YSSpotifySearchController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSSpotifySearchController.h"
#import "SpotifyAPI.h"
#import "YSTrack.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import <QuartzCore/QuartzCore.h>

@interface YSSpotifySearchController ()
@property (nonatomic, strong) NSArray *songs;

@property (strong, nonatomic) IBOutlet UITextField *searchBox;
@property (strong, nonatomic) IBOutlet iCarousel *carousel;

@end

@implementation YSSpotifySearchController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    double delay = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.searchBox becomeFirstResponder];
    });
    
    self.searchBox.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.searchBox.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    
    self.searchBox.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:@"Type an artist, song, or album"
                                    attributes:@{
                                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                                 NSFontAttributeName : [UIFont fontWithName:@"Futura-Medium" size:17.0]
                                                 }
     ];
    
}

- (IBAction)searchPressed:(id)sender
{
    [self search:self.searchBox.text];
    [self.view endEditing:YES];
}

- (void) search:(NSString *)search
{
    __weak YSSpotifySearchController *weakSelf = self;
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
    
    /*
    UILabel *label = [UILabel new];
    label.text = track.name;
    [label sizeThatFits:CGSizeMake(100, 100)];
    [trackView addSubview:label];
     */
    
    return trackView;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    YSTrack *song = self.songs[index];
    NSLog(@"Selected song: %@", song.name);
    [[API sharedAPI] sendSong:song withCallback:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"IT WORKED!!!!");
        } else {
            NSLog(@"it didnt work: %@", error);
        }
    }];
}

@end
