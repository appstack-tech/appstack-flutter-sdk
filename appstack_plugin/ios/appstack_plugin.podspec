#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint appstack_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'appstack_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Track events and revenue with Apple Search Ads attribution for Flutter apps.'
  s.description      = <<-DESC
Flutter plugin for Appstack Attribution SDK. Track app installs, user events, and revenue with Apple Search Ads attribution support.
                       DESC
  s.homepage         = 'https://appstack.tech'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Appstack' => 'support@appstack.tech' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  
  # Note: This plugin uses Swift Package Manager for the iOS SDK dependency.
  # The AppstackSDK is referenced via Package.swift in ios/appstack_plugin/Package.swift
  # CocoaPods users: The XCFramework will be resolved via SPM integration
  
  s.platform = :ios, '14.3'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'appstack_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
