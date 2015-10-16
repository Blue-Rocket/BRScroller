//
//  BRLogFormatter.h
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#define DD_LEGACY_MACROS 0
#import <CocoaLumberjack/DDLog.h>

/**
 * Log formatter with level, timestamp, thread, file, and method details.
 *
 *  1. Log level - _DEBUG_
 *  2. Timestamp - _08162039:19.307_ which is _MMddHHmm:ss.SSS_ format, as Aug 16 20:39:19.307
 *  3. Thread - _c07_
 *  4. File name and line number - _ViewController.m:23_
 *  5. Method name - _viewWillAppear:_
 *  6. Pipe - _|_
 *  7. Message - _Hi there, ViewController_
 */
@interface BRLogFormatter : NSObject<DDLogFormatter>

@end
