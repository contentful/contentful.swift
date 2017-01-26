#!/usr/bin/ruby

use_frameworks!

target 'Contentful' do

  podspec :path => 'Contentful.podspec'

  target 'ContentfulTests' do
    inherit! :search_paths

    pod 'CatchingFire'
    pod 'CryptoSwift', '~> 0.5.2'
    pod 'Nimble', '~> 4.1.0'
    pod 'Quick', '~> 0.9.3'

  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end

