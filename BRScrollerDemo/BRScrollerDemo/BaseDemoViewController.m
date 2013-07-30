//
//  BaseDemoViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/31/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BaseDemoViewController.h"

@implementation BaseDemoViewController

- (void)viewDidLoad {
	self.navigationItem.title = NSStringFromClass([self class]);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)];
#ifdef __IPHONE_7_0
	// on iOS 7, don't extend the scroll view under the navigation bar / status bar
	if ( [self respondsToSelector:@selector(setEdgesForExtendedLayout:)] ) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (IBAction)done:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
