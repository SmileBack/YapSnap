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

- (void) uploadPhoto:(NSURL *)imageURL withCallback:(UploadedFileCallback)callback
{
    NSString *fileName = [NSString stringWithFormat:@"%d_%f", [YSUser currentUser].userID.intValue, [NSDate date].timeIntervalSince1970];
    NSString *bucket = @"audiomessenger/uploads/photo";

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = bucket;
    uploadRequest.key = fileName;
    uploadRequest.body = imageURL;
    uploadRequest.contentType = @"image/png"; //Saved as PNG in AddTextVC
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;

    NSString *url = [NSString stringWithFormat:@"https://s3.amazonaws.com/%@/%@", bucket, fileName];
    
    [[transferManager upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Amazon image error: %@", task.error);
            callback(nil, nil, task.error);
        } else {
            AWSS3TransferManagerUploadOutput *output = task.result;
            callback(url, output.ETag, nil);
        }
        return nil;
    }];
}

#pragma mark - Genric
- (void) uploadFile:(NSURL *)fileURL withName:(NSString *)fileName andContentType:(NSString *)contentType andBucket:(NSString *)bucket withCallback:(UploadedFileCallback)callback
{
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = bucket;
    uploadRequest.key = fileName;
    uploadRequest.body = fileURL;
    uploadRequest.contentType = contentType;
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

#pragma mark - iTunes
- (void) uploadiTunesTrack:(NSURL *)fileURL withCallback:(UploadedFileCallback)callback
{
    NSString *fileName = [NSString stringWithFormat:@"%d_%f", [YSUser currentUser].userID.intValue, [NSDate date].timeIntervalSince1970];
    
    [self uploadFile:fileURL
            withName:fileName
      andContentType:@"audio/mp4" //TODO what is the type????????
           andBucket:@"audiomessenger/uploads/itunes/songs"
        withCallback:callback];
}

- (void) uploadiTunesArtwork:(NSURL *)fileURL withCallback:(UploadedFileCallback)callback
{
    NSString *fileName = [NSString stringWithFormat:@"%d_%f", [YSUser currentUser].userID.intValue, [NSDate date].timeIntervalSince1970];
    
    [self uploadFile:fileURL
            withName:fileName
      andContentType:@"image/png" //TODO what is the type????????
           andBucket:@"audiomessenger/uploads/itunes/artwork"
        withCallback:callback];
}

@end
