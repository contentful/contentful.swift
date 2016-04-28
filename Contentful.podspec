Pod::Spec.new do |s|
  s.name             = "Contentful"
  s.version          = "0.2.1"
  s.summary          = "Swift SDK for Contentful's Content Delivery API."
  s.homepage         = "https://github.com/contentful/contentful.swift/"
  s.social_media_url = 'https://twitter.com/contentful'

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }

  s.authors      = { "Boris Bügling" => "boris@buegling.com" }
  s.source       = { :git => "https://github.com/contentful/contentful.swift.git",
                     :tag => s.version.to_s }
  s.requires_arc = true

  s.source_files         = 'Sources/*.swift'

  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'

  s.dependency 'Decodable', '~> 0.4.2'
  s.dependency 'Interstellar', '~> 1.4.0'
  s.dependency '🕕', '0.0.1'
end
