//
//  Environment.h
//
//  Created by Jon Deokule on 10/15/12.


#import <Foundation/Foundation.h>

@interface Environment : NSObject

FOUNDATION_EXPORT NSString *const ENV_DEBUG;
FOUNDATION_EXPORT NSString *const ENV_RELEASE;

@property (nonatomic, readonly) NSString *configuration;

@property (nonatomic, strong) NSString *apiURL;
@property (nonatomic, strong) NSString *crashyliticsApiKey;

+ (Environment *)sharedInstance;

- (BOOL) isProd;
- (BOOL) isDev;

@end
