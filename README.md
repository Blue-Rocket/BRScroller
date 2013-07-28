BRScroller
==========

Memory-friendly iOS horizontally scrolling view.

BRScroller provides a `UIScrollView` subclass that efficiently manages
horizontally-scrolling *pages* of content, much like a `UITableView`
manages vertically-scrolling *rows* of content. In addition, BRScroller
provides some scaffolding for the memory-efficient and UI-responsive
display of high resolution content, such as photos. In this respect,
BRScroller can be used in similar ways as
[MWPhotoBrowser](https://github.com/mwaterfall/MWPhotoBrowser),
[TTPhotoViewController](https://github.com/enormego/three20), or
[EGOPhotoViewer](https://github.com/enormego/PhotoViewer). Where
BRScroller differs, however, is that it does not provide any built-in
UI. Instead of forcing any particular UI, you can build any UI that
suits your application, relying on BRScroller to perform just the
low-level (dare I say, *boring*) work of helping you managing memory
efficiently.

Requirements
------------

BRScroller has no dependencies outside the iOS SDK. It supports
deployment to any iOS device, version **5.1** or later.

Example Usage
-------------

See the **BRScrollerDemo** project, included in this project, that
demonstrates different ways of using BRScroller. Here is a description
of the demos available in that project:

* **SimpleViewController**

  A very simple demonstration of `BRScrollView` that shows how the basic
  principles of managed page views are handled. If you've every coded a
  `UITableViewController` you should feel right at home.

* **AsyncPhotoViewController**

  A demo that showcases a common scenario: the display of images in a
  similar way to the iOS built-in Photos app. Smaller _preview_ images
  are shown while scrolling between photos. When you pinch to zoom any
  particular photo, the full-resolution version of that is shown.
  
* **DemoTiledViewController**

  Demonstrates using a `CATiledLayer` backed view to render arbitrarily
  large content.

* **MultiViewController**

  Shows how multiple scrollers can be used together, with a full-screen
  scroller representing full-detail pages of content and a small ribbon
  scroller representing thumbnails corresponding to the full-detail
  pages. Tapping on a thumbnail causes the full-detail page to animate
  into view.

* **InfiniteViewController**

  BRScroller sports an _infinite_ mode, in which the number of pages are
  not necessarily known in advance (or there are just a lot of pages!).
  This mode works by defining an origin page, and all other pages are
  relative to that origin (e.g. **-1** for immediately left or **1** for
  immediately right).

* **ReverseViewController**

  BRScroller sports a _reverse layout_ mode, in which the pages are
  positioned in right-to-left order, rather than the default 
  left-to-right order.

Static Framework Project Integration
------------------------------------

You can integrate BRScroller into your project in a couple of ways.
First, the BRScroller Xcode project includes a target called
**BRScroller.framework** that builds a static library framework. Build
that target, which will produce a `BRScroller.framework` bundle at the
root project directory. Copy that framework into your project and add it
as a build dependency.

You must also add the following linker build dependencies, which you can
do by clicking the **+** button in the **Link Binary With Libraries**
section of the **Build Phases** tab in the project settings:

 * `QuartzCore.framework`

Next, add `-ObjC` as an **Other Linker Flags** build setting.

Finally, you'll need to add the path to the directory containing the
`BRScroller.framework` bundle as a **Framework Search Paths** value in
the **Build Settings** tab of the project settings.

Dependent Project Integration
-----------------------------

The other way you can integrate BRScroller into your project is to add
the BRScroller Xcode project as a dependent project of your project. The
BRScroller Xcode project includes a target called  **BRScroller** that
builds a static library. You can use that target as a dependency in your
own project. The **BRScrollerDemo** project is set up this way.

To do this, drag the **BRScroller.xcodeproj** onto your project in the
Project Navigator. Then go to the **Build Phases** tab of your project's
settings. Expand the **Target Dependencies** section and click the **+**
button. You should see the `BRScroller` static library target as an
available option. Select that and click the **Add** button.

You must also add the following linker build dependencies, which you can
do by clicking the **+** button in the **Link Binary With Libraries**
section of the **Build Phases** tab in the project settings:

 * `QuartzCore.framework`

Next, add `-ObjC` as an **Other Linker Flags** build setting.

Finally, you'll need to add the path to the directory containing the
*BRScroller.xcodeproj* file as a **Header Search Paths** value in the
**Build Settings** tab of the project settings. If you have added
BRScroller as a git submodule to your own project, then the path might
be something like `"$(PROJECT_DIR)/../BRScroller"`.

More detailed information on Xcode dependent projects can be found
online, for example
[here](http://www.cocoanetics.com/2011/12/sub-projects-in-xcode/) or
[here](https://www.google.com/search?q=xcode+dependent+projects).
