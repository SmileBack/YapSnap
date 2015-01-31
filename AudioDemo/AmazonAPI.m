//
//  AmazonAPI.m
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "AmazonAPI.h"
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>
#import <AWSiOSSDKv2/AWSS3TransferManager.h>
#import <AWSiOSSDKv2/AWSCredentialsProvider.h>
#import "YSUser.h"

static AmazonAPI *sharedAPI;

@implementation AmazonAPI

+ (AmazonAPI *) sharedAPI
{
    if (!sharedAPI) {
        sharedAPI = [AmazonAPI new];
        [sharedAPI setupAws];
    }

    return sharedAPI;
}

- (void) setupAws
{
//    AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:AWSRegionUSEast1
//                                                                                                        accountId:@"193191061924"
//                                                                                                   identityPoolId:nil
//                                                                                                    unauthRoleArn:nil
//                                                                                                      authRoleArn:nil];

    AWSStaticCredentialsProvider *creds = [AWSStaticCredentialsProvider credentialsWithAccessKey:@"AKIAIDOJIA33U2VL5OPA"
                                                                                       secretKey:@"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"];

    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionUSEast1
                                                                          credentialsProvider:creds];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}

- (void) uploadYap:(NSURL *)fileURL withCallback:(UploadedFileCallback)callback
{
    NSString *fileName = [NSString stringWithFormat:@"%d_%f", [YSUser currentUser].userID.intValue, [NSDate date].timeIntervalSince1970];
    NSString *bucket = @"audiomessenger/uploads/voice_message/recording";

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = bucket;
    uploadRequest.key = fileName;
    uploadRequest.body = fileURL;
    uploadRequest.contentType = @"audio/mp4";
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;

    NSString *url = [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", bucket, fileName];
    
    [[transferManager upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            callback(nil, nil, task.error);
        } else {
            AWSS3TransferManagerUploadOutput *output = task.result;
            callback(url, output.ETag, nil);
        }
        return nil;
    }];
}

@end
