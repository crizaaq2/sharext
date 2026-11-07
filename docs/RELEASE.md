# Release: signing, builds, what to hand out

## Android

### What the local build is

`flutter build apk --release --flavor prod` currently signs with the **debug**
key (`app/android/app/build.gradle.kts`), so the APK installs on any phone for
testing. That is not a release signature.

### The real keystore (SX-004, owner's job, human only)

```bash
keytool -genkeypair -v -keystore sharext-release.jks -storetype JKS \
  -keyalg RSA -keysize 4096 -validity 10000 -alias sharext \
  -dname "CN=ShAre XT, O=ShAre XT, C=SO"
```

1. Keep `sharext-release.jks` **out of the repository** (`.gitignore` already
   covers `*.jks`, `*.keystore`, `key.properties`).
2. Back it up in two places you control. Losing it means you can never update
   the app for the people who installed it. Losing it does **not** lose anyone's
   identity: identity is a per-device key, not the app signature.
3. Put the password and the base64 keystore in GitHub Secrets
   (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
   `ANDROID_KEY_PASSWORD`) and decode them in CI; never commit them.
4. In `build.gradle.kts`, replace the `signingConfigs.getByName("debug")` line
   with a `signingConfigs { create("release") { … } }` block that reads
   `key.properties`.

### Builds

```bash
./tools/build_android.sh                        # analyze, test, universal APK
flutter build apk --release --flavor prod --split-per-abi   # smaller APKs
flutter build appbundle --release --flavor prod             # Play, later
```

Artifacts land in `app/build/app/outputs/flutter-apk/`.

Flavors: `dev` (application id `com.sharext.app.dev`, amber-tinted icon,
`app_name` "ShAre XT dev") installs next to `prod`. The direct-download build
declares `REQUEST_INSTALL_PACKAGES`; keep that out of the Play variant
(SX-004, not wired yet).

## Windows

A Flutter Windows build needs a Windows host: CMake drives MSVC and Flutter does
not cross-compile the runner.

```powershell
.\tools\build_windows.ps1
# EXE: app\build\windows\x64\runner\Release\sharext.exe
# ZIP: sharext-windows.zip  (hand this to people)
```

Unsigned builds trigger SmartScreen ("Windows protected your PC"). That is
expected until SX-804 signs the installer with a code-signing certificate; tell
testers to choose "More info → Run anyway". The installer itself (MSIX or Inno
Setup) is SX-804 and not built yet — until then hand out the ZIP.

The `.github/workflows/ci.yml` Windows job builds the same ZIP on
`windows-latest` for every push, so a downloadable EXE exists even if you only
have Linux and a phone.

## Artificial facts to keep straight

- `docs/PLAN.md` §2a: force-stopped or never-opened apps cannot be woken. Say it
  plainly in the release notes; never promise delivery to a force-stopped phone.
- No INTERNET permission is declared, on purpose. Do not add one.
- The APK does not carry the Bluetooth plugin yet (Sprint 0). A release build now
  is a UI and core preview, not the 1.0 radio build.
