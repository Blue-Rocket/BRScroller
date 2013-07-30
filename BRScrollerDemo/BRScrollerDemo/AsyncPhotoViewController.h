//
//  ViewController.h
//  BRScrollerDemo
//
//  Demonstration of a paging scroller used to display small "preview" images that are replaced
//  by large full-detail images when pinched to zoom.
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BaseDemoViewController.h"

@class BRScrollerView;

@interface AsyncPhotoViewController : BaseDemoViewController

@property (nonatomic, strong) IBOutlet BRScrollerView *scrollView;

@end
