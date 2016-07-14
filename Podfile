# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'WYFISA' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WYFISA
  pod 'TesseractOCRiOS', '4.0.0'
  pod 'GPUImage', '0.1.7'
  pod "STRegex", "~> 0.3.1"
  pod 'SQLite.swift', '~> 0.10.1'

  target 'WYFISATests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WYFISAUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end

    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
