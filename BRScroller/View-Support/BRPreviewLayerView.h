//
//  BRPreviewLayerView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@class BRPreviewLayerView;

NS_ASSUME_NONNULL_BEGIN

/**
 API to provide preview image content when needed by @c BRPreviewLayerView.
 */
@protocol BRPreviewLayerViewDelegate <NSObject>

@required

/**
 Get the desired preview display size for the requesting view.
 
 @param view The view requesting the preview display size.
 
 @return The desired preview size.
 */
- (CGSize)displaySizeForView:(BRPreviewLayerView *)view;

/**
 Get a unique key that identifies the current image in the requesting view.
 
 @param view The view requesting the unique identifier.
 
 @return A unique identifier.
 */
- (id)previewImageKeyForView:(BRPreviewLayerView *)view;

/**
 Render a preview image for the requesting view. This method must support being called from a 
 background thread.
 
 @param view The view requesting the preview image.
 @param key  The unique identifier of the image being requested.
 @param size The desired size of the preview image.
 
 @return The preview image to display.
 */
- (UIImage *)renderPreviewImageForView:(BRPreviewLayerView *)view key:(id)key atSize:(CGSize)size;

@optional

/**
 Quickly provide a preview image for the requesting view. This method will be called from the 
 main thread and should only be used to return images that are readily available. If an image
 is @i not readily available, this method should return @c nil and then
 @c renderPreviewImageForView:key:atSize: will be called later from a background thread.
 
 @param view The view requesting the preview image.
 @param size The requested preview image size.
 
 @return The preview image, or @c nil if one is not available.
 */
- (nullable UIImage *)previewImageForView:(BRPreviewLayerView *)view atSize:(CGSize)size;

/**
 Callback invoked when a preview image has been shown.
 
 @param view The view showing the preview image.
 */
- (void)didDisplayPreviewImageForView:(BRPreviewLayerView *)view;
@end

/**
 A view that supports asynchronous rendering of a @c preview image layer, which can be
 swaped out with @c normal resolution content as needed. This is designed to facilitate
 smooth UI interactions in scenarios such as quickly scrolling through many images: the
 @c preview images can be small and load quickly while the @c normal images can be very
 large and too slow to load while scrolling.
 
 The delegate is responsible for providing the preview image content. The @c contentView
 property is designed to hold the @c normal content.
 */
@interface BRPreviewLayerView : UIView

/** The delegate. */
@property (nonatomic, weak, nullable) id<BRPreviewLayerViewDelegate> delegate;

/** The size to render preview images within. The images will be aspect-fit scaled to this size. */
@property (nonatomic) CGSize previewSize;

/** Flag to disable the preview image layer completely. */
@property (nonatomic, getter = isPreviewDisabled) BOOL previewDisabled;

/** The @c normal content view. */
@property (nonatomic, strong, nullable) UIView *contentView;

/**
 Inform the receiver that the @c contentView is changed and a new preview image should be rendered.
 It is not necessary to call this method when setting a new instance on the @c contentView property.
 Call this method when the content of the configured @c contentView changes. For example if 
 @c contentView is a @c UIImageView then call this method after changing the @c image property of
 that view to handle the display of the preview layer as appropriate. The contentView will be hidden 
 when this is called.
 */
- (void)updatedContent;

@end

NS_ASSUME_NONNULL_END
