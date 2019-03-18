CocoaLumberjack as a framework for iOS.

This project provides a way to integrate the
[CocoaLumberjack](https://github.com/robbiehanson/CocoaLumberjack) project easily
into your own project, by providing a static library framework that you can add
rather than adding the sources directly. It also provides a simple mechanism to use
class-level logging, similar to what the venerable
[log4j](http://logging.apache.org/) provides in Java.

# Example Usage

First to most easily integrate logging, add `BRCocoaLumberjack.h` to your PCH, something like this:

```objc
	#ifdef __OBJC__
		#import <UIKit/UIKit.h>
		#import <Foundation/Foundation.h>
		#import <BRCocoaLumberjack/BRCocoaLumberjack.h>
	#endif
```

Then you must configure the logging system, someplace early in the life of your application. How about in `main()`:

```objc
	int main(int argc, char *argv[]) {
		@autoreleasepool {
	#ifdef LOGGING
			BRLoggingSetupDefaultLogging();
	#endif
			return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
		}
	}
```

Note the `#ifdef LOGGING`. Unless you define this macro, logging anything less that
at the *ERROR* level will not be enabled. Add `LOGGING=1` to your *Preprocessor
Macros* build setting, probably just for the *Debug* configuration.

Then, when you want to log something in Objective-C, use the handy macros `log4X` or
`DDLogX`, where `X`is one of *Error*, *Warn*, *Info*, *Debug*, or *Trace*. For
example:

```objc
	DDLogDebug(@"Hi there, from %@", NSStringFromClass([self class]));
	log4Debug(@"Hi again, from %@", NSStringFromClass([self class]));
```

Note that `DDLogDebug` and `log4Debug` produce the same results, they are just two
different styles to accomplish the same thing, which is something like this:

	DEBUG 08162039:19.307 c07    ViewController.m:23 viewWillAppear:| Hi there, ViewController

The world loves variety, and the `DDLog` style comes from CocoaLumberjack while the
`log4` comes from the [log4cocoa](http://log4cocoa.sourceforge.net/) project (and is
more similar to log4j if you're coming from that world).

The logging output is by using the default formatter, which reads like this:

 1. Log level - _DEBUG_
 2. Timestamp - _08162039:19.307_ which is _MMddHHmm:ss.SSS_ format, as Aug 16 20:39:19.307
 3. Thread - _c07_
 4. File name and line number - _ViewController.m:23_
 5. Method name - _viewWillAppear:_
 6. Pipe - _|_
 7. Message - _Hi there, ViewController_

# Logging configuration

The `BRLoggingSetupDefaultLogging()` function will configure **INFO** level logging
by default. It will also look for a file named `LocalEnvironment.plist` in your
application's main bundle, which should contain a dictionary with another dictionary
on the key `logging`. The `logging` dictionary can contain the special key `default`
to set the default logging level, to one of `error`, `warn`, `info`, `debug`, or
`trace`.

In addition, class-level logging can be configured by adding more keys to the
`logging` dictionary, named after the class you want to configure. Classes inherit
the configured log level of their parent, too, which allows you to configure entire
class hierarchies by setting a logging level at the root of the hierarchy.

For example, the following configures a default level of `warn` and the class
`AppDelegate` (and any sub-classes) will use the `debug` level:

```xml
<plist version="1.0">
<dict>
	<key>logging</key>
	<dict>
		<key>default</key>
		<string>warn</string>
		<key>AppDelegate</key>
		<string>debug</string>
	</dict>
</dict>
</plist>
```

# Project Integration

You can integrate BRCocoaLumberjack via [CocoaPods](http://cocoapods.org/), or
manually as either a dependent project or static framework.

## via CocoaPods

Install CocoaPods if not already available:

```bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and create a file named `Podfile` with
contents similar to this:

	platform :ios, '5.0' 
	pod 'BRCocoaLumberjack', '~> 1.8.1'

Install into your project:

``` bash
$ pod install
```

Open your project in Xcode using the **.xcworkspace** file CocoaPods generated.

### Pod logging

Note that as BRCocoaLumberjack disables all but `Error` level logging unless a
`LOGGING=1` preprocessor macro is defined, _other_ pods included in your app's
project that also use BRCocoaLumberjack will not do any logging by default,
because the generated **Pods.xcodeproj** will not have that macro defined. You
can work around this by adding the following to your `Podfile`:

```ruby
post_install do |installer|
	installer.pods_project.build_configurations.each do |config|
		if config.name == 'Debug'
			# for Debug, add LOGGING=1 macro to support BRCocoaLumberjack logging within pods themselves
			config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'DEBUG=1']
			config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] |= ['LOGGING=1']
		end
	end
end
```

That will basically add `LOGGING=1` to the Pod project's **Debug** configuration.

## via Static Framework

Using this approach you'll build a static library framework that you can manually
integrate into your own project. After cloning the BRCocoaLumberjack repository,
first initialize git submodules. For example:

	git clone git@github.com:Blue-Rocket/BRCocoaLumberjack.git
	cd BRCocoaLumberjack
	git submodule update --init
	
This will pull in the relevant submodules, e.g. CocoaLumberjack.

The BRCocoaLumberjack Xcode project includes a target called
**BRCocoaLumberjack.framework** that builds a static library framework. Build that
target, which will produce a `Framework/Release/BRCocoaLumberjack.framework` bundle
at the root project directory. Copy that framework into your project and add it as a
build dependency.

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you may need to add the path to the directory containing the
`BRFullTextSearch.framework` bundle as a **Framework Search Paths** value in the
**Build Settings** tab of the project settings. Xcode may do this for you, however.
