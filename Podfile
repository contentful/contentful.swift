use_frameworks!

target 'Contentful' do

podspec :path => 'Contentful.podspec'

end

target 'ContentfulTests' do

pod 'CatchingFire'
pod 'CryptoSwift'
pod 'Nimble'
pod 'Quick'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
