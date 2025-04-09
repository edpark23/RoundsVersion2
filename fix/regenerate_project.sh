#!/bin/bash

echo "Closing Xcode..."
osascript -e 'tell application "Xcode" to quit'
sleep 2

# Create backup of original project
echo "Creating backup of original project..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p backup/$TIMESTAMP
cp -R RoundsVersion2.xcodeproj backup/$TIMESTAMP/

# Remove problematic files
echo "Removing package manager state files..."
rm -rf RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
rm -f RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings

# Create a fresh Package.resolved file if it doesn't exist
mkdir -p RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# Find all references to the problematic GUID and replace them
echo "Replacing all references to the problematic GUID..."
NEW_UUID=$(uuidgen | tr -d "-")
PROBLEM_GUID="PACKAGE:1XUWI700IGKT1UPF9LK12H80YCLPSXEI8"
NEW_GUID="PACKAGE:$NEW_UUID"

find RoundsVersion2.xcodeproj -type f -exec sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" {} \;

# Clean any Xcode caches
echo "Cleaning project..."
xcodebuild clean -project RoundsVersion2.xcodeproj -scheme RoundsVersion2

echo ""
echo "Project structure has been regenerated."
echo "Please open the project in Xcode and let it resolve the packages again."
echo ""
echo "If you still encounter issues, you may need to manually delete the DerivedData folder:"
echo "~/Library/Developer/Xcode/DerivedData/RoundsVersion2-*" 