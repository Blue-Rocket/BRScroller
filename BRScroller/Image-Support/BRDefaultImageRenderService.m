//
//  BRDefaultImageRenderService.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRDefaultImageRenderService.h"

#import "BRScrollerLogging.h"
#import "BRDrawingUtils.h"

static dispatch_queue_t PersistenceQueue;
static dispatch_once_t PersistenceQueueToken;

@implementation BRDefaultImageRenderService

- (id)init {
	if ( (self = [super init]) ) {
		self.jpegImageQuality = 0.9;
		self.cacheDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"BRDefaultImageRenderService"];
	}
	dispatch_once(&PersistenceQueueToken, ^{
		PersistenceQueue = dispatch_queue_create("BRDefaultImageRenderService.Persistence", DISPATCH_QUEUE_SERIAL);
	});
	return self;
}

- (void)setCacheDir:(NSString *)dir {
	_cacheDir = dir;
	if ( dir && ![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:nil] ) {
		[[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
	}
	DDLogDebug(@"Using image cache dir %@", dir);
}

- (NSString *)pathForCachedImage:(NSString *)key {
	return [[self.cacheDir stringByAppendingPathComponent:key]
			stringByAppendingPathExtension:([key hasSuffix:@".jpg"] ? @"jpg" : @"png")];
}

- (void)imageForKey:(NSString *)key
			context:(nullable id)context
	   renderedWith:(UIImage *  _Nonnull (^)(NSString * _Nonnull, id _Nonnull))renderBlock
		confirmWith:(nullable BOOL (^)(NSString * _Nonnull, id _Nonnull))stillNeededBlock
			handler:(void (^)(NSString * _Nonnull, id _Nonnull, UIImage * _Nonnull))handlerBlock {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// look for cached image file
		NSString *cacheFile = [self pathForCachedImage:key];
		
		void (^handleImageResult)(UIImage *, BOOL) = ^(UIImage *image, BOOL decompress) {
			if ( stillNeededBlock && !stillNeededBlock(key, context) ) {
				return;
			}
			UIImage *resultImage = image;
			
			if ( decompress ) {
				// decompress (jpg,png,etc) image into raw bitmap memory by drawing it, then we can blast it on the main queue
				CGContextRef bitmap = BRScrollerCreateBitmapContextNoAlpha(image.size);
				CGContextDrawImage(bitmap, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
				resultImage = [UIImage imageWithCGImage:CGBitmapContextCreateImage(bitmap)];

			}
			
			handlerBlock(key, context, resultImage);
		};
		
		UIImage *image = nil;
		BOOL decompress = YES;
		if ( [[NSFileManager new] fileExistsAtPath:cacheFile] ) {
			// found cached file
			image = [UIImage imageWithContentsOfFile:cacheFile];
		} else {
			// need to generate image
			image = renderBlock(key, context);
			
			// save the image data to a cache file
			dispatch_async(PersistenceQueue, ^{
				NSData *imageData = ([key hasSuffix:@".jpg"]
									 ? UIImageJPEGRepresentation(image, self.jpegImageQuality)
									 : UIImagePNGRepresentation(image));
				[imageData writeToFile:cacheFile atomically:YES];
			});
			decompress = NO;
		}
		
		handleImageResult(image, decompress);
	});
}

@end
