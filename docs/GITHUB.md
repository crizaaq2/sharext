# Getting the APK and the EXE from GitHub

Nothing here needs a secret, a keystore or a paid service. Free GitHub runners do
the Windows build you cannot do on Linux.

## 1. Put this repository on GitHub

```bash
git remote add origin git@github.com:<your-account>/sharext.git   # or the https URL
git branch -M main
git push -u origin main
```

Create the empty repository on github.com first (no README, no .gitignore — this
repository already has them).

If the branch you have locally is not `main`, the workflow still runs on any
branch push; `main` is only the default trigger in `ci.yml`.

## 2. Watch the build

Repository → **Actions** → the run for your push. Three jobs:

| Job | What it produces |
|---|---|
| `core` | `dart analyze --fatal-infos` + 43 tests for `sx_core` |
| `android` | `sharext-apk-universal`, `sharext-apk-per-abi` artifacts |
| `windows` | `sharext-windows.zip` (contains `sharext.exe`) |

Open a finished run and scroll to **Artifacts** to download the ZIP. Artifacts are
kept for 90 days by default.

The Windows job is the only place an EXE can be produced: Flutter compiles the
Windows runner with MSVC and cannot cross-compile from Linux or macOS. The runner
is `windows-latest`, so MSVC and CMake are already installed.

## 3. Publish a release people can download from

```bash
git tag v0.1.0
git push origin v0.1.0
```

`.github/workflows/release.yml` then builds everything again, renames the files
(`sharext-v0.1.0-universal.apk`, `-arm64.apk`, `-arm32.apk`,
`sharext-v0.1.0-windows.zip`), adds `SHA256SUMS.txt` and creates the GitHub
Release with all of them attached. That release page is the link to give people —
it works on a phone with no account.

You can also run the release workflow by hand: Actions → **release** → *Run
workflow*. In that case the tag condition is skipped, so no Release is created and
the files stay as run artifacts.

## 4. Before the first public release

- **Signing.** CI currently builds with the debug key, like the local build. For a
  real release signature, add the four secrets described in `docs/RELEASE.md` and
  switch `build.gradle.kts` to the `release` signing config. Never commit the
  keystore.
- **Name clearance** (SX-1107) — check trademarks and app stores before publishing
  under the name.
- **Play Store** — the Play build must not declare `REQUEST_INSTALL_PACKAGES`. The
  direct-download variant keeps it (SX-004).
- **Windows signing** (SX-804) — until then SmartScreen warns on the unsigned EXE.

## 5. Costs and limits

- Public repositories: Actions minutes are free; private ones consume your
  included minutes (the Windows job is the expensive one, about 4–6 minutes).
- Largest file: the universal APK is about 52 MB, well under GitHub's 100 MB file
  limit and the 2 GB release asset limit.
- Do not commit `dist/*.apk`; builds come from CI, and binaries in git history are
  hard to remove later.

## 6. If a job fails

| Symptom | Cause and fix |
|---|---|
| `You must specify a --flavor` | Use `--flavor prod` (already in both workflows) |
| `flutter analyze --fatal-infos` fails | A new lint or deprecation; fix it locally first |
| Windows job: `Unable to find suitable Visual Studio toolchain` | Rare on `windows-latest`; re-run the job. Locally, install "Desktop development with C++" |
| Windows job: build succeeds but no EXE | The output is `build\windows\x64\runner\Release\sharext.exe`; the zip step packages that folder |
| Android job: `SDK location not found` | `actions/setup-java` plus the Flutter action handle it; check `android/local.properties` is not committed (it must stay local) |

## 7. If the release job fails with 403

The release job needs to write to the repository. On a new repository GitHub may
default `GITHUB_TOKEN` to read-only, which downgrades the workflow's
`permissions: contents: write`. Fix it once:

Settings → Actions → General → Workflow permissions → **Read and write
permissions** → Save, then re-run the workflow. The build jobs themselves need
nothing beyond read access.
