//
//  BRAsyncImageView.h
//  BRScroller
//
//  Created by Matt on 7/15/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@class BRAsyncImageView;

NS_ASSUME_NONNULL_BEGIN

/**
 API for callback methods from the @c BRAsyncImageView.
 */
@protocol BRAsyncImageViewDelegate <NSObject>

@optional

/**
 Callback invoked from the view's configured queue after decoding the image but before displaying it.
 
 @param view  The image view displaying the image.
 @param image The image to be displayed.
 */
- (void)asyncImageView:(BRAsyncImageView *)view willDisplayImage:(UIImage *)image;

/**
 Callback invoked on the main queue when an image has been loaded and displayed.
 
 @param view The view that displayed the image.
 */
- (void)didDisplayAsyncImageInView:(BRAsyncImageView *)view;

@end

/**
 View that loads and displays images in the background. Set @c imageURL to point to some image,
 then call loadImage to have the image loaded in the background. By default, a
 single serial queue is used for loading all images. You can provide your own
 queue by setting the queue property.
 
 Instead of setting the `imageURL` property, the `imageData` property can be set
 to image data, and that data will be loaded into a UIImage object. The data will
 still be decoded in the background.
 */
@interface BRAsyncImageView : UIView

/** A queue to process images on. Defaults to a custom serial background queue. */
@property (nonatomic) dispatch_queue_t queue;

/** A URL to an image to display. Can be set to @c nil to release any existing image. */
@property (nonatomic, strong, nullable) NSURL *imageURL;

/** Raw image data to display, instead of using @c imageURL. */
@property (nonatomic, strong, nullable) NSData *imageData;

/** A delegate to receive messages about image display progress. */
@property (nonatomic, weak, nullable) id<BRAsyncImageViewDelegate> delegate;

/** Flag to tell if an image is loaded. */
@property (nonatomic, readonly, getter = isLoaded) BOOL loaded;

/** Flag to tell if an image is loading. */
@property (nonatomic, readonly, getter = isLoading) BOOL loading;

/** The size of the currently shown image. */
@property (nonatomic, readonly) CGSize imageSize;

/**
 Load and display the configure image, using @c imageData if configured or else @c imageURL.
 */
- (void)loadImage;

@end

NS_ASSUME_NONNULL_END
