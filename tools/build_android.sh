#!/usr/bin/env bash
# Build the release APK. Run tools/setup_toolchain.sh once first.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root/app"

flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release --flavor prod

echo
echo "APK:"
ls -lh build/app/outputs/flutter-apk/*.apk
