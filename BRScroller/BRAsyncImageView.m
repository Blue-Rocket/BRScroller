//
//  BRAsyncImageView.m
//  BRScroller
//
//  Created by Matt on 7/15/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRAsyncImageView.h"

#import <QuartzCore/QuartzCore.h>

#import "BRScrollerLogging.h"
#import "BRScrollerUtilities.h"

// our serial update queue... only one writer allowed
static dispatch_queue_t AsyncImageQueue;

static NSString * const kImageURLKey = @"BR.imageURL";

@implementation BRAsyncImageView {
	NSURL *imageURL;
	NSData *imageData;
	CALayer *imageLayer;
	CGSize imageSize;
	dispatch_queue_t queue;
}

@synthesize imageURL, queue;
@synthesize imageData;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        [self initializeBRAsyncImageViewDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ( (self = [super initWithCoder:aDecoder]) ) {
		[self initializeBRAsyncImageViewDefaults];
	}
	return self;
}

- (void)initializeBRAsyncImageViewDefaults {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		AsyncImageQueue = dispatch_queue_create("us.bluerocket.AsyncImage", DISPATCH_QUEUE_SERIAL);
	});
	
	queue = AsyncImageQueue; // default to global serial queue

	imageLayer = [CALayer layer];
	imageLayer.contentsGravity = self.layer.contentsGravity;
	imageLayer.bounds = self.bounds;
	imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
	imageLayer.position = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
	imageLayer.hidden = YES;
	
	[self.layer addSublayer:imageLayer];
}

#pragma mark - Accessors

- (BOOL)isLoaded {
	@synchronized( self ) {
		return imageLayer.contents != nil;
	}
}

- (BOOL)isLoading {
	@synchronized( self ) {
		return (imageLayer.contents == nil && [imageLayer valueForKey:kImageURLKey] != nil);
	}
}

- (CGSize)imageSize {
	return imageSize;
}

- (void)setImageURL:(NSURL *)theURL {
	@synchronized( self ) {
		NSURL *currURL = [imageLayer valueForKey:kImageURLKey];
		if ( theURL == nil || ![currURL isEqual:theURL] ) {
			[CATransaction begin]; {
				[CATransaction setDisableActions:YES];
				imageLayer.contents = nil;
				imageLayer.hidden = YES;
				[imageLayer setValue:nil forKey:kImageURLKey];
			} [CATransaction commit];
			imageURL = theURL;
			imageSize = CGSizeZero;
		}
	}
}

#pragma mark - Public API

- (void)loadImage {
	NSURL *theURL;
	NSURL *currURL;
	@synchronized( self ) {
		theURL = imageURL;
		currURL = [imageLayer valueForKey:kImageURLKey];
		if ( theURL == nil || [currURL isEqual:theURL] ) {
			return;
		}
		[imageLayer setValue:theURL forKey:kImageURLKey];
	}
	dispatch_async(queue, ^{
		NSError *error = nil;
		NSData *data = imageData;
		if ( data == nil ) {
			data = [NSData dataWithContentsOfURL:theURL options:NSDataReadingMappedIfSafe error:&error];
			if ( error != nil ) {
				DDLogError(@"Error reading image URL %@: %@", theURL, [error description]);
				return;
			}
		}
		UIImage *img = [[UIImage alloc] initWithData:data];
		if ( img == nil ) {
			return;
		}
		
		// decode and load image into memory, while still on background thread
		UIGraphicsBeginImageContext(img.size);
		[img drawAtPoint:CGPointZero];
		img = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		__weak id<BRAsyncImageViewDelegate> del = self.delegate;
		
		if ( [del respondsToSelector:@selector(asyncImageView:willDisplayImage:)] ) {
			[del asyncImageView:self willDisplayImage:img];
		}
		
		@synchronized( self ) {
			if ( imageURL != nil && [theURL isEqual:imageURL] ) {
				imageSize = img.size;
				[CATransaction begin]; {
					[CATransaction setDisableActions:YES];
					imageLayer.contents = (id)img.CGImage;
					imageLayer.hidden = NO;
					[self setImageLayerPosition];
				} [CATransaction commit];
				dispatch_async(dispatch_get_main_queue(), ^{
					if ( [del respondsToSelector:@selector(didDisplayAsyncImageInView:)] ) {
						[del didDisplayAsyncImageInView:self];
					}
				});
			}
		}
	});
}

#pragma mark - Layout

- (void)setImageLayerPosition {
	const CGSize viewSize = self.bounds.size;
	imageLayer.position = CGPointMake(viewSize.width * 0.5, viewSize.height * 0.5);
	imageLayer.bounds = CGRectMake(0, 0, viewSize.width, viewSize.height);
}

- (void)setContentMode:(UIViewContentMode)theMode {
	[super setContentMode:theMode];
	imageLayer.contentsGravity = self.layer.contentsGravity;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setImageLayerPosition];
}

- (CGSize)sizeThatFits:(CGSize)toFit {
	CGSize contentSize = (imageSize.width < 1 ? toFit : imageSize);
	CGSize aspectFitSize = BRAspectSizeToFit(contentSize, toFit);
	return aspectFitSize;
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self setImageLayerPosition];
}

- (void)setBounds:(CGRect)bounds {
	[super setBounds:bounds];
	[self setImageLayerPosition];
}

@end
