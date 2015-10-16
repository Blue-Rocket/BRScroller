Pod::Spec.new do |s|

  s.name         = "BRScroller"
  s.version      = "1.4.0"
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
  
  s.default_subspec = 'All'
  
  s.subspec 'All' do |sp|
  	sp.source_files = "BRScroller/BRScroller.h"
    sp.dependency 'BRScroller/Core'
    sp.dependency 'BRScroller/View-Support'
	sp.dependency 'BRScroller/Image-Support'
	sp.dependency 'BRScroller/PDF'
  end
  
  s.subspec 'Core' do |as|
  	as.source_files = "BRScroller/Core.h", "BRScroller/Core"
    as.dependency 'BRCocoaLumberjack', '~> 2.0'
  end
  
  s.subspec 'View-Support' do |as|
  	as.source_files = "BRScroller/View-Support.h", "BRScroller/View-Support"
  	as.dependency 'BRScroller/Core'
  end
  
  s.subspec 'Image-Support' do |as|
  	as.source_files = "BRScroller/Image-Support.h", "BRScroller/Image-Support"
  	as.dependency 'BRScroller/View-Support'
  end
  
  s.subspec 'PDF' do |as|
  	as.source_files = "BRScroller/PDF.h", "BRScroller/PDF"
	as.dependency 'BRScroller/Image-Support'
  end
  
end
