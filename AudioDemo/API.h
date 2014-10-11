//
//  API.h
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Unirest.h>

@interface API : NSObject

+ (UNIHTTPJsonResponse *) postToPath:(NSString *)path withParameters:(NSMutableDictionary *)parameters;
+ (UNIHTTPJsonResponse *) postYap;

@end
