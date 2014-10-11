//
//  Global.h
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/11/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Global : NSObject

+ (void) storeValue:(NSString*)value forKey:(NSString*)key;
+ (NSString*) retrieveValueForKey:(NSString*)key;

@end
