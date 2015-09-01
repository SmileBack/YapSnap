//
//  YSSongTrimmer.m
//  YapTap
//
//  Created by Jon Deokule on 8/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSongTrimmer.h"
#import <AVFoundation/AVFoundation.h>

@interface YSSongTrimmer()
@property (nonatomic, strong) YSiTunesUpload *upload;
@end

@implementation YSSongTrimmer

+ (YSSongTrimmer *) songTrimmerWithSong:(YSiTunesUpload *)upload
{
    YSSongTrimmer *trimmer = [YSSongTrimmer new];
    trimmer.upload = upload;
    return trimmer;
}

- (void) trim:(TrimmedSongCallback)callback
{
    AVAsset *trackAsset = [AVAsset assetWithURL:self.upload.trackURL];

    CMTime start = CMTimeMakeWithSeconds(self.upload.startTime, 1);
    CMTime end = CMTimeMakeWithSeconds(self.upload.endTime, 1);
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [AudioTrack insertTimeRange:CMTimeRangeMake(start, end)
                        ofTrack:[[trackAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    [self export:mixComposition withCallback:callback];
}

- (void) export:(AVMutableComposition *) mixComposition withCallback:(TrimmedSongCallback)callback
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"trimmedAudio-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    // 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(url.description, nil);
        });
    }];
}



@end
