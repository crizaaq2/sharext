# ShAre XT

Share text, links, emojis, stickers and any file with the people around you — over
Bluetooth only. No internet, no accounts, no servers, no analytics.

Current stage: **Sprint 0** (foundations) with a working app shell and the pure-Dart
core started. Nothing in this repository talks to a radio yet; see
`docs/STATUS.md` for exactly what is and is not real.

## What is here

```
app/                  Flutter app (Android + Windows targets)
packages/sx_core/     pure Dart: SLP/1 constants, framing, identity, outbox, transports
docs/                 PLAN.md (source of truth), STATUS.md, DESIGN.md, PROTOCOL.md, qa/
tools/                brand asset generation, local build scripts
.github/workflows/    CI: analyze + tests + APK + Windows build
```

## Build the Android APK

Requires Flutter stable and a JDK 17. Toolchain setup on a fresh Linux box is
scripted in `tools/setup_toolchain.sh` (no root needed).

```bash
./tools/build_android.sh          # release APK -> build/app/outputs/flutter-apk/
```

The APK produced locally is signed with a throwaway local keystore so it can be
sideloaded for testing. Real release signing is SX-004 and the keystore stays with
the owner (see `docs/RELEASE.md`).

## Build the Windows EXE

A Flutter Windows build needs a Windows host: the Windows runner is compiled with
MSVC by CMake, and Flutter does not cross-compile it from Linux or macOS.

```powershell
flutter build windows --release   # build\windows\x64\runner\Release\sharext.exe
```

`tools/build_windows.ps1` wraps that and zips the result. On every push,
`.github/workflows/ci.yml` builds the same thing on a `windows-latest` runner and
uploads `sharext-windows.zip`, so a Windows EXE is always downloadable from CI even
if you only have Linux around.

## Tests

```bash
cd packages/sx_core && dart test
cd app && flutter analyze && flutter test
```
