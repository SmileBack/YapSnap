//
//  Environment.m
//
//
//  Created by Jon Deokule on 10/15/12.
//

#import "Environment.h"

@implementation Environment

NSString *const ENV_DEBUG = @"Debug";
NSString *const ENV_RELEASE = @"Release";

static Environment *sharedInstance = nil;

@synthesize configuration = _configuration;

- (void)initializeSharedInstance
{
    _configuration = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Configuration"];
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* envsPListPath = [bundle pathForResource:@
                               "Environments" ofType:@"plist"];
    NSDictionary* environments = [[NSDictionary alloc] initWithContentsOfFile:envsPListPath];
    NSDictionary* environment = [environments objectForKey:_configuration];

    self.apiURL = [environment valueForKey:@"apiURL"];
    NSLog(@"Environment configuration initialized.\nEnvironment: %@\nAPI URL: %@", _configuration, self.apiURL);

    self.crashyliticsApiKey = environment[@"CrashyliticsApiKey"];
}

#pragma mark - Lifecycle Methods

+ (Environment *)sharedInstance
{
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [Environment new];
            [sharedInstance initializeSharedInstance];
        }
        return sharedInstance;
    }
}

- (BOOL) isProd
{
    return [ENV_RELEASE isEqualToString:self.configuration];
}

- (BOOL) isDev
{
    return [ENV_DEBUG isEqualToString:self.configuration];
}

@end