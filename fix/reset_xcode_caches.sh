#!/bin/bash

echo "Closing Xcode..."
osascript -e 'tell application "Xcode" to quit'
sleep 2

echo "Removing Package.resolved file..."
rm -f RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

echo "Removing workspace state file..."
rm -f RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings

echo "Cleaning project files..."
xcodebuild clean -project RoundsVersion2.xcodeproj -scheme RoundsVersion2

echo "All caches reset. Now please try opening the project in Xcode again."
echo "If you still have issues, you may need to manually delete the DerivedData folder for this project:"
echo "~/Library/Developer/Xcode/DerivedData/RoundsVersion2-*" 