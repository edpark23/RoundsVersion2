#!/bin/bash

# Generate a new UUID to replace the problematic one
NEW_UUID=$(uuidgen | tr -d "-")
PROBLEM_GUID="PACKAGE:1XUWI700IGKT1UPF9LK12H80YCLPSXEI8"
NEW_GUID="PACKAGE:$NEW_UUID"

echo "Generated new UUID: $NEW_UUID"
echo "Replacing all instances of $PROBLEM_GUID with $NEW_GUID"

# Create backup directory if it doesn't exist
mkdir -p backup/latest

# Process main project file
if [ -f "RoundsVersion2.xcodeproj/project.pbxproj" ]; then
    echo "Backing up project.pbxproj..."
    cp RoundsVersion2.xcodeproj/project.pbxproj backup/latest/project.pbxproj.backup
    
    echo "Fixing project.pbxproj..."
    sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" RoundsVersion2.xcodeproj/project.pbxproj
    echo "project.pbxproj updated"
fi

# Process workspace data
if [ -f "RoundsVersion2.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    echo "Backing up contents.xcworkspacedata..."
    cp RoundsVersion2.xcodeproj/project.xcworkspace/contents.xcworkspacedata backup/latest/contents.xcworkspacedata.backup
    
    echo "Fixing contents.xcworkspacedata..."
    sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" RoundsVersion2.xcodeproj/project.xcworkspace/contents.xcworkspacedata
    echo "contents.xcworkspacedata updated"
fi

# Check for xcshareddata directory
if [ -d "RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata" ]; then
    echo "Checking for package references in xcshareddata..."
    
    # Process package resolution files if they exist
    if [ -f "RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
        echo "Backing up Package.resolved..."
        cp RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved backup/latest/Package.resolved.backup
        
        echo "Fixing Package.resolved..."
        sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
        echo "Package.resolved updated"
    fi
    
    # Process other potential workspace settings
    find RoundsVersion2.xcodeproj/project.xcworkspace/xcshareddata -type f -exec grep -l "$PROBLEM_GUID" {} \; | while read file; do
        echo "Backing up $file..."
        cp "$file" "backup/latest/$(basename "$file").backup"
        
        echo "Fixing $file..."
        sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" "$file"
        echo "$file updated"
    done
fi

# Process xcuserdata if it exists
if [ -d "RoundsVersion2.xcodeproj/xcuserdata" ]; then
    echo "Checking for references in xcuserdata..."
    find RoundsVersion2.xcodeproj/xcuserdata -type f -exec grep -l "$PROBLEM_GUID" {} \; | while read file; do
        echo "Backing up $file..."
        cp "$file" "backup/latest/$(basename "$file").backup"
        
        echo "Fixing $file..."
        sed -i '' "s/$PROBLEM_GUID/$NEW_GUID/g" "$file"
        echo "$file updated"
    done
fi

echo "All files processed. Please clean and rebuild your project in Xcode." 