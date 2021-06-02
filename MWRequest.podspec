Pod::Spec.new do |spec|
  spec.name         = "MWRequest"
  spec.version      = "0.2.4"
  spec.summary      = "HTTP request wrapper."
  spec.homepage     = "https://github.com/levinli303/mwrequest.git"
  spec.license      = "MIT"
  spec.author             = { "Levin Li" => "lilinfeng303@outlook.com" }

  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.9"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/levinli303/mwrequest.git", :tag => "#{spec.version}" }

  spec.source_files  = "Sources/**/*.swift"
end
