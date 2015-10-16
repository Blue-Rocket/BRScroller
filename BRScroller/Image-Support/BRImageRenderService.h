//
//  BRImageRenderService.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 API for a service that can render images using background threads, with caching support.
 */
@protocol BRImageRenderService <NSObject>

/**
 Obtain an image, possibly cached, using asynchronous callbacks.
 
 @param key              A unique key for the image. This key will be used for caching.
 @param context          Some object that can be passed back in the blocks.
 @param renderBlock      A block that handles rendering or loading an image. This block will be called from a background thread.
 @param stillNeededBlock An optional block that can be used to prevent calling the @c handlerBlock after the @renderBlock has finished.
 @param handlerBlock     A block to accept the final image. This block will be called from a background thread.
 */
- (void)imageForKey:(NSString *)key
			context:(nullable id)context
	   renderedWith:(UIImage * (^)(NSString *key, id context))renderBlock
		confirmWith:(nullable BOOL (^)(NSString *key, id context))stillNeededBlock
			handler:(void (^)(NSString *key, id context, UIImage *image))handlerBlock;

@end

NS_ASSUME_NONNULL_END
