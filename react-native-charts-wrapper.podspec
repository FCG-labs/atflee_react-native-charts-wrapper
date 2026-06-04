require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

fabric_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'

Pod::Spec.new do |s|
  s.name         = 'react-native-charts-wrapper'
  s.version      = package["version"]
  s.summary      = package["description"]
  s.author       = package["author"]

  s.homepage     = package["homepage"]

  s.license      = package["license"]
  s.platform     = :ios, "12.0"

  s.source       = { :git => "https://github.com/wuxudong/react-native-charts-wrapper.git", :tag => "#{s.version}" }
  s.source_files = "ios/ReactNativeCharts/**/*.{h,m,mm,swift}"
  s.static_framework = true

  # Stable Swift module name regardless of pod dash/underscore rewriting.
  # Used by ObjC++ Fabric wrappers as: `#import <ReactNativeCharts/ReactNativeCharts-Swift.h>`
  s.module_name = 'ReactNativeCharts'

  s.swift_version = '5.0'
  s.dependency 'SwiftyJSON', '5.0'
  s.dependency 'DGCharts', '5.0.0'

  # New Architecture (Fabric) support.
  # When RCT_NEW_ARCH_ENABLED=1, install_modules_dependencies injects
  # React-RCTFabric / React-Codegen / hermes headers & defines so that
  # the *.mm component view files compile correctly.
  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency 'React-Core'
  end
end
