Pod::Spec.new do |spec|
  spec.name         = "MWRequest"
  spec.version      = "0.2.9"
  spec.summary      = "HTTP request wrapper."
  spec.homepage     = "https://github.com/levinli303/mwrequest.git"
  spec.license      = "MIT"
  spec.author             = { "Levin Li" => "lilinfeng303@outlook.com" }

  spec.ios.deployment_target = "11.0"
  spec.osx.deployment_target = "10.13"
  spec.watchos.deployment_target = "4.0"
  spec.tvos.deployment_target = "11.0"
  spec.swift_version = "5.5"

  spec.source       = { :git => "https://github.com/levinli303/mwrequest.git", :tag => "#{spec.version}" }

  spec.source_files  = "Sources/**/*.swift"
end
