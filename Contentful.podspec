#!/usr/bin/ruby

require 'dotenv/load'

Pod::Spec.new do |spec|
  spec.name             = "Contentful"
  spec.version          = ENV['CONTENTFUL_SDK_VERSION']
  spec.summary          = "Swift SDK for Contentful's Content Delivery API."
  spec.homepage         = "https://github.com/contentful/contentful.swift/"
  spec.social_media_url = 'https://twitter.com/contentful'

  spec.license = {
      :type => 'MIT',
      :file => 'LICENSE'
  }

  spec.authors      = { "JP Wright" => "jp@contentful.com", "Boris Bügling" => "boris@buegling.com" }
  spec.source       = { :git => "https://github.com/contentful/contentful.swift.git",
                        :tag => spec.version.to_s }
  spec.requires_arc = true

  spec.swift_version             = '5'
  spec.source_files              = 'Sources/Contentful/*.swift'
  
  ## Platform specific source code.
  spec.ios.source_files          = 'Sources/Contentful/UIKit/*.swift'
  spec.watchos.source_files      = 'Sources/Contentful/UIKit/*.swift'
  spec.tvos.source_files         = 'Sources/Contentful/UIKit/*.swift'
  spec.osx.source_files          = 'Sources/Contentful/AppKit/*.swift'
 
  spec.ios.deployment_target     = '8.0'
  spec.osx.deployment_target     = '10.10'
  spec.watchos.deployment_target = '2.0'
  spec.tvos.deployment_target    = '9.0'

  spec.subspec 'ImageOptions' do |subspec|
    subspec.source_files = 'Sources/Contentful/ImageOptions/*.swift'
  end
end

