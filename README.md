BRScroller
==========

Memory-friendly iOS horizontally scrolling view.

BRScroller provides a `UIScrollView` subclass that efficiently manages horizontally-scrolling *pages* of content, much like a `UITableView` manages vertically-scrolling *rows* of content. In addition, BRScroller provides some scaffolding for the memory-efficient and UI-responsive display of high resolution content, such as photos. In this respect, BRScroller can be used in similar ways as [MWPhotoBrowser](https://github.com/mwaterfall/MWPhotoBrowser), [TTPhotoViewController](https://github.com/enormego/three20), or [EGOPhotoViewer](https://github.com/enormego/PhotoViewer). Where BRScroller differs, however, is that it does not provide any built-in UI. Instead of forcing any particular UI, you can build any UI that suits your application, relying on BRScroller to perform just the low-level (dare I say, *boring*) work of helping you managing memory efficiently.

Requirements
------------

BRScroller has no dependencies outside the iOS SDK. It supports deployment to any iOS device, version **5.1** or later.

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
  similar way to the iOS built-in Photos app.

Static Framework Project Integration
------------------------------------

You can integrate BRScroller into your project in a couple of ways.
First, the BRScroller Xcode project includes a target called
**BRScroller.framework** that builds a static library framework. Build
that target, which will produce a `BRScroller.framework` bundle at the
root project directory. Copy that framework into your project and add it
as a build dependency.

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you'll need to add the path to the directory containing the
`BRScroller.framework` bundle as a **Framework Search Paths** value in
the **Build Settings** tab of the project settings.

Dependent Project Integration -----------------------------

The other way you can integrate BRScroller into your project is to add
the BRScroller Xcode project as a dependent project of your project. The
BRScroller Xcode project includes a target called  **BRScroller** that
builds a static library. You can use that target as a dependency in your
own project. The **BRScrollerDemo** project is set up this way.

To do this, drag the **BRScroller.xcodeproj** onto your project in the
Project Navigator. Then go to the **Build Phases** tab of your project's
settings. Expand the **Target Dependencies** section and click the **+**
button. You should see the **BRScroller** static library target as an
available option. Select that and click the **Add** button.

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you'll need to add the path to the directory containing the
*BRScroller.xcodeproj* file as a **Header Search Paths** value in the
**Build Settings** tab of the project settings. If you have added
BRFullTextSearch as a git submodule to your own project, then the path
might be something like **"$(PROJECT_DIR)/../BRScroller"**.
