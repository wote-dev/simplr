#!/usr/bin/env ruby

# Script to help add widget extension target to Simplr.xcodeproj
# This script provides the necessary project.pbxproj modifications

require 'securerandom'

# Generate UUIDs for the new target and files
widget_target_uuid = SecureRandom.hex(12).upcase
widget_bundle_uuid = SecureRandom.hex(12).upcase
widget_swift_uuid = SecureRandom.hex(12).upcase
widget_task_uuid = SecureRandom.hex(12).upcase
widget_info_uuid = SecureRandom.hex(12).upcase
widget_entitlements_uuid = SecureRandom.hex(12).upcase
app_entitlements_uuid = SecureRandom.hex(12).upcase

puts "Widget Extension Target Configuration"
puts "======================================"
puts
puts "Generated UUIDs for project.pbxproj:"
puts "Widget Target: #{widget_target_uuid}"
puts "Widget Bundle: #{widget_bundle_uuid}"
puts "Widget Swift: #{widget_swift_uuid}"
puts "Widget Task: #{widget_task_uuid}"
puts "Widget Info: #{widget_info_uuid}"
puts "Widget Entitlements: #{widget_entitlements_uuid}"
puts "App Entitlements: #{app_entitlements_uuid}"
puts
puts "IMPORTANT: Use Xcode's built-in 'Add Target' feature instead of manual editing."
puts "This script is provided for reference only."
puts
puts "Steps to add widget target:"
puts "1. Open Simplr.xcodeproj in Xcode"
puts "2. Select project → Add Target → Widget Extension"
puts "3. Name: SimplrWidget"
puts "4. Bundle ID: blackcubesolutions.Simplr.SimplrWidget"
puts "5. Replace generated files with the ones I created"
puts "6. Configure App Groups as described in WIDGET_SETUP_GUIDE.md"