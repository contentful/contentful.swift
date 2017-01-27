#!/usr/bin/ruby

source 'https://github.com/CocoaPods/Specs.git'
#source 'https://github.com/contentful/CocoaPodsSpecs.git'

use_frameworks!

podspec :path => 'Contentful.podspec'

# iOS
target 'Contentful_iOS' do

  platform :ios, '8.0'

  target 'ContentfulTests' do
    inherit! :search_paths

    pod 'CatchingFire', :git => 'https://github.com/loudmouth/CatchingFire.git'
    pod 'CryptoSwift', :git => 'https://github.com/krzyzanowskim/CryptoSwift.git', :branch => 'develop'
    pod 'Nimble'
    pod 'Quick'

  end
end

# macOS
target 'Contentful_macOS' do
  platform :osx, '10.12'
end

# tvOS
target 'Contentful_tvOS' do
  platform :tvos, '9.0'
end

# watchOS
target 'Contentful_watchOS' do
  platform :watchos, '2.0'
end

