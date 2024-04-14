#!/bin/bash
# Exit if any command fails
set -e
# Echo all commands for debug purposes
set -x

appName=tudo
appId=net.cachapa.tudo

# Copy the portable app to the Flatpak-based location
appDir=/app/bin
mkdir -p $appDir
cp -r $appName data lib $appDir/

# Install the icon
iconDir=/app/share/icons/hicolor/scalable/apps
mkdir -p $iconDir
cp $appId.svg $iconDir/

# Install the desktop file.
desktopFileDir=/app/share/applications
mkdir -p $desktopFileDir
cp -v $appId.desktop $desktopFileDir/

# Install the AppStream metadata file.
metadataDir=/app/share/metainfo
mkdir -p $metadataDir
cp $appId.metainfo.xml $metadataDir/
