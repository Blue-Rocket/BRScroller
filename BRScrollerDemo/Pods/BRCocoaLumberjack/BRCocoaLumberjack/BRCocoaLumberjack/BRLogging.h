//
//  BRLogging.h
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

@protocol DDLogFormatter;

/**
 * Set up default logging.
 *
 * The default logging level will be set to `INFO`. It will also look for a file named
 * `LocalEnvironment.plist` in your application's main bundle, which should contain a
 * dictionary with another dictionary on the key `logging`. The `logging` dictionary
 * can contain the special key `default` to set the default logging level, to one of
 * `error`, `warn`, `info`, `debug`, or `trace`.
 *
 * In addition, class-level logging can be configured by adding more keys to the
 * `logging` dictionary, named after the class you want to configure. Classes inherit
 * the configured log level of their parent, too, which allows you to configure entire
 * class hierarchies by setting a logging level at the root of the hierarchy.
 *
 * @see BRLoggingSetupDefaultLoggingWithBundle(NSBundle *bundle)
 */
void BRLoggingSetupDefaultLogging(void);

/**
 * Set up default logging.
 *
 * The default logging level will be set to `INFO`. It will also look for a file named
 * `LocalEnvironment.plist` in your provided bundle, which should contain a
 * dictionary with another dictionary on the key `logging`. The `logging` dictionary
 * can contain the special key `default` to set the default logging level, to one of
 * `error`, `warn`, `info`, `debug`, or `trace`.
 *
 * In addition, class-level logging can be configured by adding more keys to the
 * `logging` dictionary, named after the class you want to configure. Classes inherit
 * the configured log level of their parent, too, which allows you to configure entire
 * class hierarchies by setting a logging level at the root of the hierarchy.
 *
 * After loading the configuration, the `BRLoggingSetupLogging()` method will be called.
 *
 * @param bundle the bundle to load the `LocalEnvironment.plist` resource from
 * @see BRLoggingSetupLogging(NSArray *loggers, id<DDLogFormatter> formatter, int defaultLevel, NSDictionary *dynamicLogging)
 */
void BRLoggingSetupDefaultLoggingWithBundle(NSBundle *bundle);

/**
 * Set up logging.
 *
 * The `dynamicLogging` dictionary can contain the special key `default` to set the
 * default logging level, or names of Objective-C classes. The associated values
 * should be `NSString` objects; any of `error`, `warn`, `info`, `debug`, or `trace`.
 * Classes inherit the configured log level of their parent, too, which allows you to
 * configure entire class hierarchies by setting a logging level at the root of the hierarchy.
 *
 * @param loggers an array of `DDLogger` objects to log to
 * @param formatter the `DDLogFormatter` to use for all loggers
 * @param defaultLevel the default logging level to use
 * @param dynamicLogging a dictionary of class name keys (as `NSString` objects) with
 *        associated log level values (as `NSString` objects)
 */
void BRLoggingSetupLogging(NSArray *loggers, id<DDLogFormatter> formatter, int defaultLevel, NSDictionary *dynamicLogging);

/**
 * Get the configured log level for a given class.
 *
 * This method relies on `BRLoggingSetupLogging()` having been called previously to configure
 * class-level logging.
 *
 * @see BRLoggingSetupLogging(NSArray *loggers, id<DDLogFormatter> formatter, int defaultLevel, NSDictionary *dynamicLogging)
 */
int BRLogLevelForClass(Class aClass);
