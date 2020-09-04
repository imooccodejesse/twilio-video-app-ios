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

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

#import "TVIScreenVideoFormatFactory.h"

@implementation TVIScreenVideoFormatFactory

- (TVIVideoFormat *)makeVideoFormatForContent:(TVIScreenContent)content {
    TVIVideoFormat *videoFormat = [TVIVideoFormat new];
    videoFormat.frameRate = 30;
    // TODO: Set pixelFormat?

    // TODO: Clean all of this up
    CGSize screenSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width * UIScreen.mainScreen.nativeScale,
                                   UIScreen.mainScreen.bounds.size.height * UIScreen.mainScreen.nativeScale);

    switch (content) {
        case TVIScreenContentDefault:
            videoFormat.dimensions = (CMVideoDimensions){screenSize.width, screenSize.height};
            break;
        case TVIScreenContentVideo:
        {
            int maxWidthOrHeight = 886;
            CGSize downscaledTarget = CGSizeMake(maxWidthOrHeight, maxWidthOrHeight);
            CGRect origin = CGRectMake(CGPointZero.x, CGPointZero.y, downscaledTarget.width, downscaledTarget.height);
            CGRect fitRect = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(screenSize, origin));
            CGSize outputSize = fitRect.size;
            videoFormat.dimensions = (CMVideoDimensions){outputSize.width, outputSize.height};
            break;
        }
    }
    
    return videoFormat;
}

@end
