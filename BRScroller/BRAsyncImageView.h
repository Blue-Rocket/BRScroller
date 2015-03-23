//
//  BRAsyncImageView.h
//  BRScroller
//
//  Load and display images in the background. Set imageURL to point to some image.
//  Then call loadImage to have the image loaded in the background. By default, a
//  single serial queue is used for loading all images. You can provide your own
//  queue by setting the queue property.
//
//  Instead of setting the `imageURL` property, the `imageData` property can be set
//  to image data, and that data will be loaded into a UIImage object. The data will
//  still be decoded in the background.
//
//  Created by Matt on 7/15/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@class BRAsyncImageView;

@protocol BRAsyncImageViewDelegate <NSObject>

@optional

// called from the configured queue after decoding the image, before display
- (void)asyncImageView:(BRAsyncImageView *)view willDisplayImage:(UIImage *)image;

// called on the main queue when the image has been loaded and displayed
- (void)didDisplayAsyncImageInView:(BRAsyncImageView *)view;

@end

@interface BRAsyncImageView : UIView

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, weak) id<BRAsyncImageViewDelegate> delegate;

@property (nonatomic, readonly, getter = isLoaded) BOOL loaded;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;
@property (nonatomic, readonly) CGSize imageSize;

- (void)loadImage;

@end
