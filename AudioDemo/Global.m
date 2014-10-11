//
//  Global.m
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/11/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"

@implementation Global

// Just a convenient place to put these methods for now.
// Used for storing and retrieving global string variables.
+ (void) storeValue:(NSString*)value forKey:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
}

+ (NSString*) retrieveValueForKey:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:key];
}

@end
