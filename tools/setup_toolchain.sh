#!/usr/bin/env bash
# Installs a build toolchain without root: Flutter, Temurin JDK 17 and the
# Android SDK command line tools, all under $HOME/sdk.
#
# Nothing here survives an archived cloud workspace: re-run it after a restore.
set -euo pipefail

SDK="${SDK:-$HOME/sdk}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.9}"
JDK_MAJOR="${JDK_MAJOR:-17}"
CMDLINE_TOOLS="commandlinetools-linux-13114758_latest.zip"

mkdir -p "$SDK"
cd "$SDK"

if [ ! -d flutter ]; then
  echo "== Flutter $FLUTTER_VERSION =="
  curl -fL -o flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar -xf flutter.tar.xz
  rm flutter.tar.xz
fi

if ! ls -d jdk-* >/dev/null 2>&1; then
  echo "== Temurin JDK $JDK_MAJOR =="
  curl -fL -o jdk.tar.gz \
    "https://api.adoptium.net/v3/binary/latest/${JDK_MAJOR}/ga/linux/x64/jdk/hotspot/normal/eclipse"
  tar -xzf jdk.tar.gz
  rm jdk.tar.gz
fi
JDK_DIR="$(ls -d "$SDK"/jdk-* | head -1)"

if [ ! -x "$SDK/android-sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "== Android command line tools =="
  mkdir -p android-sdk/cmdline-tools
  curl -fL -o cmdline-tools.zip \
    "https://dl.google.com/android/repository/${CMDLINE_TOOLS}"
  unzip -q -o cmdline-tools.zip -d android-sdk/cmdline-tools
  rm -rf android-sdk/cmdline-tools/latest
  mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest
  rm cmdline-tools.zip
fi

export JAVA_HOME="$JDK_DIR"
export PATH="$SDK/flutter/bin:$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$SDK/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --licenses >/dev/null
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" \
  "platform-tools" "platforms;android-36" "build-tools;36.0.0"

printf 'sdk.dir=%s\nflutter.sdk=%s\n' "$ANDROID_HOME" "$SDK/flutter" > android-local.properties
flutter --version
echo
echo "Add this to your shell profile:"
echo "  export JAVA_HOME=$JAVA_HOME"
echo "  export ANDROID_HOME=$ANDROID_HOME"
echo "  export PATH=$SDK/flutter/bin:\$JAVA_HOME/bin:\$PATH"
