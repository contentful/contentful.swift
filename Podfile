#!/usr/bin/ruby

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/contentful/CocoaPodsSpecs.git'

platform :ios, "8.0"

use_frameworks!

target 'Contentful' do

  podspec :path => 'Contentful.podspec'

  pod 'Interstellar', :git => 'https://github.com/loudmouth/Interstellar.git'
  pod 'Decodable', '~> 0.5'

  target 'ContentfulTests' do
    inherit! :search_paths

    pod 'CatchingFire', :git => 'https://github.com/loudmouth/CatchingFire.git'
    pod 'CryptoSwift', :git => 'https://github.com/krzyzanowskim/CryptoSwift.git', :branch => 'develop'
    pod 'Nimble'
    pod 'Quick'

  end
end

