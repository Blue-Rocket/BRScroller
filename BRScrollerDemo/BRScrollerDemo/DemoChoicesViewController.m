//
//  DemoChoicesViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/16/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "DemoChoicesViewController.h"

#import "AsyncPhotoViewController.h"

@implementation DemoChoicesViewController {
	NSArray *classes;
}

- (id)initWithStyle:(UITableViewStyle)style {
	if ( (self = [super initWithStyle:style]) ) {
		classes = @[@"SimpleViewController", @"AsyncPhotoViewController", @"DemoTiledViewController", @"MultiViewController"];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
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
	switch ( indexPath.row ) {
		case 0:
			cell.detailTextLabel.text = @"Basic BRScrollerView with simple page views.";
			break;
			
		case 1:
			cell.detailTextLabel.text = @"Zoomable photo browser using BRPreviewLayerView, BRAsyncImageView, and friends.";
			break;
			
		case 2:
			cell.detailTextLabel.text = @"Zoomable CATiledLayer demonstration.";
			break;
			
		case 3:
			cell.detailTextLabel.text = @"A full-screen paging scroller with a small thumbnail navigation scroller.";
			break;
			
		default:
			cell.detailTextLabel.text = nil;
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
