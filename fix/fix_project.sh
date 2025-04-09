#!/bin/bash
cp RoundsVersion2.xcodeproj/project.pbxproj RoundsVersion2.xcodeproj/project.pbxproj.old
cat RoundsVersion2.xcodeproj/project.pbxproj | sed "s/PACKAGE:1XUWI700IGKT1UPF9LK12H80YCLPSXEI8::MAINGROUP/PACKAGE:$(uuidgen | tr -d \"-\")::MAINGROUP/g" > fix/new_project.pbxproj
cp fix/new_project.pbxproj RoundsVersion2.xcodeproj/project.pbxproj
