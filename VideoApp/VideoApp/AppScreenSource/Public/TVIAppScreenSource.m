//
//  Copyright (C) 2020 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <CoreMedia/CoreMedia.h>
#import <ReplayKit/ReplayKit.h>

#import "TVIAppScreenSource.h"
#import "TVIAppScreenSourceOptions+Internal.h"
#import "TVIReplayKitSampleHandler.h"
#import "TVIScreenVideoFormatFactory.h"

@interface TVIAppScreenSource() <RPScreenRecorderDelegate>

@property (nonatomic, strong) TVIAppScreenSourceOptions *options;
@property (nonatomic, strong) TVIReplayKitSampleHandler *sampleHandler;
@property (nonatomic, strong) TVIScreenVideoFormatFactory *videoFormatFactory;
@property (nonatomic, strong) RPScreenRecorder *screenRecorder;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation TVIAppScreenSource

@synthesize sink;

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(nullable id<TVIAppScreenSourceDelegate>)delegate {
    TVIAppScreenSourceOptionsBuilder *builder = [[TVIAppScreenSourceOptionsBuilder alloc] initPrivate];
    TVIAppScreenSourceOptions *options = [[TVIAppScreenSourceOptions alloc] initWithBuilder:builder];
    return [self initWithOptions:options delegate:delegate];
}

- (instancetype)initWithOptions:(nonnull TVIAppScreenSourceOptions *)options
                       delegate:(nullable id<TVIAppScreenSourceDelegate>)delegate {
    self = [super init];
    if (self) {
        _options = options;
        _delegate = delegate;
        _sampleHandler = [TVIReplayKitSampleHandler new];
        _videoFormatFactory = [TVIScreenVideoFormatFactory new];
        _screenRecorder = [RPScreenRecorder sharedRecorder];
        _screenRecorder.delegate = self;
        _screenRecorder.microphoneEnabled = NO;
        _screenRecorder.cameraEnabled = NO;
        _queue = dispatch_get_main_queue();
        [self validateDelegate:delegate];
    }
    return self;
}

- (void)setDelegate:(id<TVIAppScreenSourceDelegate>)delegate {
    [self validateDelegate:delegate];
    _delegate = delegate;
}

- (BOOL)isAvailable
{
    return self.screenRecorder.isAvailable;
}

- (void)startCapture {
    [self startCaptureWithCompletion:nil];
}

- (void)startCaptureWithCompletion:(nullable TVIAppScreenSourceStartedBlock)completion {
    if (self.sink == nil) {
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:@"A sink is required. Create a TVILocalVideoTrack first."
                                                       userInfo:nil];
        [exception raise];
    }

    if (self.sink.sourceRequirements == nil) {
        TVIVideoFormat *videoFormat = [self.videoFormatFactory makeVideoFormatForContent:self.options.screenContent];
        [self.sink onVideoFormatRequest:videoFormat];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef sampleBuffer, RPSampleBufferType bufferType, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        if (error != nil) {
            dispatch_async(strongSelf.queue, ^{
                if ([strongSelf.delegate respondsToSelector:@selector(appScreenSource:didFailWithError:)]) {
                    [strongSelf.delegate appScreenSource:strongSelf didFailWithError:error];
                }
            });
            
            return;
        }
        
        [strongSelf.sampleHandler handleSample:sampleBuffer bufferType:bufferType sink:strongSelf.sink];
    } completionHandler:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        if (completion) {
            dispatch_async(strongSelf.queue, ^{
                completion(strongSelf.sink.sourceRequirements, error);
            });
        }
    }];
}

- (void)stopCapture {
    [self stopCaptureWithCompletion:nil];
}

- (void)stopCaptureWithCompletion:(nullable TVIAppScreenSourceStoppedBlock)completion {
    [self.screenRecorder stopCaptureWithHandler:^(NSError *error) {
        if (completion) {
            dispatch_async(self.queue, ^{
                completion(error);
            });
        }
    }];
}

- (BOOL)isScreencast {
    return YES;
}

- (void)requestOutputFormat:(nonnull TVIVideoFormat *)outputFormat {
    [self.sink onVideoFormatRequest:outputFormat];
}

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
    if (screenRecorder.isAvailable) {
        dispatch_async(self.queue, ^{
            if ([self.delegate respondsToSelector:@selector(appScreenSourceDidBecomeAvailable:)]) {
                [self.delegate appScreenSourceDidBecomeAvailable:self];
            }
        });
    } else {
        dispatch_async(self.queue, ^{
            if ([self.delegate respondsToSelector:@selector(appScreenSourceDidBecomeUnavailable:)]) {
                [self.delegate appScreenSourceDidBecomeUnavailable:self];
            }
        });
    }
}

- (void)validateDelegate:(id<TVIAppScreenSourceDelegate>)delegate {
    if (delegate != nil && ![delegate conformsToProtocol:@protocol(TVIAppScreenSourceDelegate)]) {
        NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:@"The supplied delegate does not conform to the TVIAppScreenSourceDelegate protocol."
                                                       userInfo:nil];
        [exception raise];
    }
}

@end
