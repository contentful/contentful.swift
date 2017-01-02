#!/usr/bin/ruby

Pod::Spec.new do |spec|
  spec.name             = "Contentful"
  spec.version          = "0.3.0"
  spec.summary          = "Swift SDK for Contentful's Content Delivery API."
  spec.homepage         = "https://github.com/contentful/contentful.swift/"
  spec.social_media_url = 'https://twitter.com/contentful'

  spec.license = {
      :type => 'MIT',
      :file => 'LICENSE'
  }

  spec.authors      = { "Boris Bügling" => "boris@buegling.com" }
  spec.source       = { :git => "https://github.com/contentful/contentful.swift.git",
                        :tag => spec.version.to_s }
  spec.requires_arc = true

  spec.source_files         = 'Sources/*.swift'

  spec.ios.deployment_target     = '8.0'
  spec.osx.deployment_target     = '10.10'
  spec.watchos.deployment_target = '2.0'
  spec.tvos.deployment_target    = '9.0'

  spec.dependency 'Decodable', '~> 0.5'
#  spec.dependency 'Interstellar', '~> 1.4.0'
#  spec.dependency '🕕', '0.1.0'
end

