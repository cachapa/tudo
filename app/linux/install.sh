#!/bin/bash

# Build app
flutter build linux

# Move application files
cp -R ../build/linux/x64/release/bundle ~/.local/share/tudo

# Create desktop entry
install -D ../../images/icon_rounded.svg ~/.local/share/icons/hicolor/scalable/apps/tudo.svg
cp tudo.desktop ~/.local/share/applications
update-desktop-database ~/.local/share/applications

