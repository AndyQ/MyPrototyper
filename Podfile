platform :ios, '7.0'
pod 'SSZipArchive', '0.3.1'
pod 'ColorPopover',  :git => 'https://github.com/AndyQ/ColorPopover', :tag => '0.0.1b'
pod 'MBProgressHUD', '0.8'
pod 'PopoverView',  :git => 'https://github.com/AndyQ/PopoverView', :tag => '0.0.4b'
pod "JSCustomBadge", '1.0.1'
pod 'InAppSettingsKit', :git => 'https://github.com/AndyQ/InAppSettingsKit'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-Acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

