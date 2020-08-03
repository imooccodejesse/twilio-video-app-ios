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

#import <Foundation/Foundation.h>

#import "Foo.h"
#import "TVIAppScreenSource.h"

@import TwilioVideo;

@interface Foo () <TVIInAppScreenCapturerDelegate>

@property (nonatomic, strong) TVIRoom *room; // Assume the roonm is already connected

@property (nonatomic, strong) TVIInAppScreenCapturer *capturer;

@end

@implementation Foo

- (void)startScreenCapture {
    self.capturer = [TVIInAppScreenCapturer new];
    self.capturer.delegate = self;
    [self.capturer startCapture];
}

- (void)capturer:(nonnull TVIInAppScreenCapturer *)capturer didStartCaptureWithTrack:(nonnull TVILocalVideoTrack *)track {
    [self.room.localParticipant publishVideoTrack: track];
}

@end
