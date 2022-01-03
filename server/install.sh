#!/bin/sh

echo "Checking sudo…"
sudo echo 👍

git pull
dart pub get

echo "Building binary…"
dart compile exe bin/main.dart -o tudo_server

echo "Moving binary to /usr/bin…"
sudo mv tudo_server /usr/bin/
