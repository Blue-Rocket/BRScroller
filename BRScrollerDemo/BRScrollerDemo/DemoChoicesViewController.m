//
//  DemoChoicesViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/16/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "DemoChoicesViewController.h"

#import "AsyncPhotoViewController.h"
#import <BRScroller/BRScrollerView.h>

@implementation DemoChoicesViewController {
	NSArray *classes;
}

- (id)initWithStyle:(UITableViewStyle)style {
	if ( (self = [super initWithStyle:style]) ) {
		classes = @[@"SimpleViewController", @"AsyncPhotoViewController", @"PdfViewController", @"DemoTiledViewController",
			  @"MultiViewController", @"InfiniteViewController", @"ReverseViewController"];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
#ifdef __IPHONE_7_0
	// on iOS 7, don't extend the scroll view under the navigation bar / status bar
	if ( [self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)] ) {
		//self.edgesForExtendedLayout = UIRectEdgeNone;
		self.automaticallyAdjustsScrollViewInsets = YES;
		self.tableView.contentInset = UIEdgeInsetsMake(22, 0, 0, 0);
	}
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

#pragma mark - Table view support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [classes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
	cell.textLabel.text = classes[indexPath.row];
	cell.detailTextLabel.font = [UIFont systemFontOfSize:9];
	NSString *descKey = [@"desc." stringByAppendingString:classes[indexPath.row]];
	cell.detailTextLabel.text = NSLocalizedString(descKey, nil);
	
	if ( [cell.textLabel.text isEqualToString:@"InfiniteViewController"] ) {
		static NSNumberFormatter *friendlyNumber;
		if ( friendlyNumber == nil ) {
			friendlyNumber = [[NSNumberFormatter alloc] init];
			[friendlyNumber setNumberStyle:NSNumberFormatterDecimalStyle];
			[friendlyNumber setMaximumFractionDigits:0];
		}
		
		cell.detailTextLabel.text = [NSString stringWithFormat:cell.detailTextLabel.text,
									 [friendlyNumber stringFromNumber:[NSDecimalNumber numberWithUnsignedInteger:kBRScrollerViewInfiniteMaximumPageIndex]]];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *dest = [[NSClassFromString(classes[indexPath.row]) alloc] initWithNibName:nil bundle:nil];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dest];
	[self presentViewController:nav animated:YES completion:NULL];
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
