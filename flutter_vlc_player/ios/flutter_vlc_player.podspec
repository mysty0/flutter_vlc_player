#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_vlc_player.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_vlc_player'
  s.version          = '3.0.3'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
  A VLC-powered alternative to Flutter video_player. Supports multiple players on one screen.
                       DESC
  s.homepage         = 'https://github.com/solid-software/flutter_vlc_player'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.dependency 'VLCKit', '~> 4.0.0a12'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
