//
//  BRDefaultImageRenderService.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRImageRenderService.h"

/**
 Default implementation of the @c BRImageRenderService API.
 */
@interface BRDefaultImageRenderService : NSObject <BRImageRenderService>

/** The cache directory path to use. Defaults to a sensible value. */
@property (nonatomic, strong) NSString *cacheDir;

/** For cached JPG images, the quality to use when encoding. */
@property (nonatomic, assign) CGFloat jpegImageQuality;

@end
