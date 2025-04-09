#!/bin/bash

# Make a backup of the current project file
echo "Making backup of project.pbxproj..."
cp RoundsVersion2.xcodeproj/project.pbxproj RoundsVersion2.xcodeproj/project.pbxproj.bak.$(date +"%Y%m%d_%H%M%S")

# Generate a new UUID
NEW_UUID=$(uuidgen | tr -d "-")
PROBLEM_GUID="PACKAGE:1XUWI700IGKT1UPF9LK12H80YCLPSXEI8::MAINGROUP"
NEW_GUID="PACKAGE:${NEW_UUID}::MAINGROUP"

echo "Generated new UUID: $NEW_UUID"
echo "Replacing '$PROBLEM_GUID' with '$NEW_GUID'"

# Perform the replacement using perl (more reliable with binary data than sed)
perl -i -pe "s/$PROBLEM_GUID/$NEW_GUID/g" RoundsVersion2.xcodeproj/project.pbxproj

echo "Replacement completed. Please try opening the project in Xcode again." 