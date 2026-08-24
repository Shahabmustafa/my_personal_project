#!/usr/bin/env bash
set -e

git clone https://github.com/flutter/flutter.git -b 3.35.3 --depth 1 /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release
