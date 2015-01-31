//
//  AmazonAPI.h
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UploadedFileCallback)(NSString *url, NSString *etag, NSError *error);

@interface AmazonAPI : NSObject

+ (AmazonAPI *) sharedAPI;

- (void) uploadYap:(NSURL *)url withCallback:(UploadedFileCallback)callback;

@end
