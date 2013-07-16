//
//  BRPreviewLayerView.h
//  BRScroller
//
//  A view that supports asynchronous rendering of a "preview" image layer, which can be
//  swaped out with "normal" resolution content as needed. This is designed to facilitate
//  smooth UI interactions in scenarios such as quickly scrolling through many images.
//
//  The delegate is responsible for providing the preview image content. The contentView
//  property is designed to hold the full-resolution content, e.g. full-sized image, etc.
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@class BRPreviewLayerView;

@protocol BRPreviewLayerViewDelegate <NSObject>
@required

- (CGSize)displaySizeForView:(BRPreviewLayerView *)view;

// return a unique key that identifies the current image
- (id)previewImageKeyForView:(BRPreviewLayerView *)view;

// render a preview image for this view, probably on a background thread
- (UIImage *)renderPreviewImageForView:(BRPreviewLayerView *)view key:(id)key atSize:(CGSize)size;

@optional
// provide a preview image for this view, very quicky as this will be called from the main thread
- (UIImage *)previewImageForView:(BRPreviewLayerView *)view atSize:(CGSize)size;

// provides a hook for the delegate to do something after the preview image is shown
- (void)didDisplayPreviewImageForView:(BRPreviewLayerView *)view;
@end

@interface BRPreviewLayerView : UIView

@property (nonatomic, weak) id<BRPreviewLayerViewDelegate> delegate;
@property (nonatomic) CGSize previewSize;
@property (nonatomic, getter = isPreviewDisabled) BOOL previewDisabled;
@property (nonatomic, strong) UIView *contentView;

// if the contentView is changed (other than by setting a new instance, e.g. changing the image
// of a UIImageView, then call this method to handle the display of the preview layer as appropriate.
// The contentView will be hidden when this is called.
- (void)updatedContent;

@end
