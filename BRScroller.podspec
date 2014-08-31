Pod::Spec.new do |s|

  s.name         = "BRScroller"
  s.version      = "1.1.0"
  s.summary      = "Memory-friendly iOS horizontally scrolling view."
  s.description  = <<-DESC
                   BRScroller provides a `UIScrollView` subclass that efficiently manages
                   horizontally-scrolling *pages* of content, much like a `UITableView`
                   manages vertically-scrolling *rows* of content.
                   DESC

  s.homepage     = "https://github.com/Blue-Rocket/BRScroller"
  s.license      = "Apache License, Version 2.0"
  s.author       = { "Matt Magoffin" => "git+matt@msqr.us" }

  s.platform     = :ios, "5.1"

  s.source       = { :git => "https://github.com/Blue-Rocket/BRScroller.git", 
  					 :tag => s.version.to_s }
  
  s.requires_arc = true
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |as|
  	as.source_files = "BRScroller/BRScroller*.{c,h,m}",
  						"BRScroller/BRScrollViewDelegate.h"
  end
  
  s.subspec 'View-Support' do |as|
  	as.source_files = "BRScroller/BRPreviewLayerView.{h,m}",
  						"BRScroller/BRCenteringScrollView.{h,m}"
  	as.dependency 'BRScroller/Core'
  end
  
  s.subspec 'Image-Support' do |as|
  	as.source_files = "BRScroller/*Image*.{h,m}"
  	as.dependency 'BRScroller/View-Support'
  end
  
end
