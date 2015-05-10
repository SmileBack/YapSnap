//
//  SpotifyArtistFactory.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "SpotifyArtistFactory.h"

@implementation SpotifyArtistFactory

+ (NSArray *) artistsForGenre:(NSString *)genre
{
    if ([genre  isEqual: @"Pop"]) {
        return @[@"Maroon 5", @"Wiz Khalifa", @"Drake", @"Ed Sheeran", @"Sam Smith", @"All Time Low", @"Meghan Trainor", @"Ellie Goulding", @"Ariana Grande", @"Nicki Minaj",@"Kendrick Lamar", @"Rihanna", @"Mark Ronson", @"Wiz Khalifa", @"Nick Jonas", @"Bruno Mars",@"WALK THE MOON", @"Fall Out Boy", @"Imagine Dragons", @"Fetty Wap", @"Sam Hunt", @"Flo Rida", @"Jason Derulo", @"Beyonce", @"Florida Georgia Line", @"Katy Perry", @"Big Sean", @"Luke Bryan",@"Charlie Puth", @"Wale", @"Sia", @"Tove Lo", @"Kelly Clarkson", @"Hozier",@"One Direction", @"Chris Brown", @"Eminem", @"Zac Brown Band", @"Darius Rucker", @"Ludacris",@"Rae Sremmurd", @"J. Cole", @"Blake Shelton", @"Jason Aldean", @"Kanye West", @"Iggy Azalea",@"Eric Church", @"Natalie La Rose", @"Selena Gomez", @"Pitbull", @"Ne-Yo", @"Lee Brice",@"Vance Joy", @"George Ezra", @"Calvin Harris", @"Trey Songz", @"Andy Grammer", @"Lord Huron", @"Carrie Underwood", @"Mumford & Sons", @"Justin Bieber", @"David Guetta", @"Kidz Bop Kids", @"Fifth Harmony", @"Cole Swindell", @"Tyga", @"Little Big Town", @"OneRepublic", @"Miranda Lambert",@"Usher", @"Echosmith", @"Jeremih", @"Thomas Rhett", @"Zedd", @"Dierks Bentley", @"Justin Timberlake", @"Kid Ink", @"Brian Wilson", @"Madonna", @"Omarion", @"AC/DC", @"Kenny Chesney", @"Tim McGraw", @"Death Cab For Cutie", @"Romeo Santos", @"Kid Rock", @"Pharrell Williams", @"Twenty One Pilots", @"DJ Snake", @"John Legend", @"Three Days Grace", @"Adele", @"Michael Jackson", @"Shawn Mendes", @"Led Zeppelin", @"Matt And Kim", @"Matt And Kim", @"Billy Currington", @"Paul McCartney", @"U2", @"Coldplay", @"Avicci"];
    } else if ([genre  isEqual: @"Hip Hop"]) {
        return @[@"Hip Hop"];
    } else if ([genre  isEqual: @"Rock"]) {
        return @[@"Rock", @"Wiz Khalifa", @"Drake", @"Ed Sheeran", @"Sam Smith", @"All Time Low"];
    } else if ([genre  isEqual: @"EDM"]) {
        return @[@"EDM"];
    } else if ([genre  isEqual: @"Country"]) {
        return @[@"Country"];
    } else if ([genre  isEqual: @"TV/Film"]) {
        return @[@"TV/Film"];
    } else if ([genre  isEqual: @"Top 100"]) {
        return @[@"Top 100"];
    } else if ([genre  isEqual: @"Latin"]) {
        return @[@"Latin"];
    } else if ([genre  isEqual: @"Humor"]) {
        return @[@"Humor"];
    } else {
        return @[@"Error"];
    }

    return @[];
}

@end
