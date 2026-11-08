# Status

Updated: 2026-11-08 (Sprint 0 foundations; first public release built by CI; the
EXE is now launched, kept alive and screenshotted by CI)

## Distribution

- Repository: <https://github.com/crizaaq2/sharext> (public, `main`).
- Release: <https://github.com/crizaaq2/sharext/releases/tag/v0.1.0> — universal /
  arm64 / arm32 APKs, `sharext-v0.1.0-windows.zip` (contains `sharext.exe`) and
  `SHA256SUMS.txt`. Assets download without a GitHub account.
- Built by `.github/workflows/release.yml` on the `v0.1.0` tag; the same jobs run
  on every push through `ci.yml`.

## Where we are

The repository, the agent operating files, the design system, the logo assets,
three languages and the pure-Dart core are in place, and **a signed, installable
Android APK builds**. The app opens on the Wadaag lens splash, walks through
onboarding, shows the radar with the people around you, opens a chat and sends a
message through the real outbox and the real framing code — over an in-memory
transport, because **no Bluetooth plugin exists yet**. Nothing in this build
touches a radio.

The Windows app has a complete source target, an icon set, a build script and a
CI job. **`sharext.exe` builds, starts and draws its first window on Windows**:
the `windows-latest` job launches the packaged binary from the folder the ZIP
ships, fails if it dies inside 12 s, then maximises the window and screenshots the
desktop. It ships inside `sharext-v0.1.0-windows.zip`. Nobody has clicked through
it on a desktop yet, and this machine still cannot cross-compile
(see `docs/RELEASE.md`).

## Verified in this session

- `dart test` in `packages/sx_core`: **43/43 pass** (framing, safety number,
  peerTag, outbox backoff/dedupe/persistence, FakeTransport, log redaction,
  flags, frozen identifiers).
- `flutter analyze` in `app`: **no issues**.
- `flutter test` in `app`: **11/11 pass** (bubble states, RTL, contrast of every
  token pair, queued → sent → delivered over the fake link, "not installed" stays
  queued, language and theme switching, demo data).
- `sharext.exe` **starts and renders on Windows**: run 42492069202 launched the
  packaged binary (pid alive after 12 s, 119.7 MB working set in the first run),
  maximised the window and captured the desktop. The result is committed as
  `docs/qa/screens/windows-first-frame.png` (1024×768): onboarding with the frozen
  logo, the headline and the Skip/Next controls. Not exercised: no button was
  pressed, no flow was walked, and a screenshot is not a Bluetooth test.
- `flutter build apk --release --flavor prod`: **built**, 54.3 MB universal APK.
  Package `com.sharext.app`, minSdk 26, signed with the local debug key (not a
  release key, see SX-004), no `INTERNET` permission.
- Brand assets regenerated from the frozen SVG geometry and reviewed visually.

Not verified, and cannot be from here: Bluetooth on real phones (needs two
phones, ADR-09), the Windows build (needs Windows), battery and background
survival (needs devices).

## Tickets

| Ticket | State | Verified by |
|---|---|---|
| SX-001 Bootstrap the repository | Done | analyze clean, all tests pass, APK builds |
| SX-002 Agent operating files | Done | `AGENTS.md`, `docs/PLAN.md`, `PROTOCOL.md`, `DESIGN.md`, `STATUS.md`, `QUESTIONS.md`, `qa/` |
| SX-003 Continuous integration | Done | `ci.yml`: core tests, Android APK and Windows EXE green; the windows job launches the packaged `sharext.exe`, keeps it alive 12 s and uploads a `sharext-windows-screenshot` artifact. Gradle now comes from a checksum-pinned mirror after GitHub's asset host answered 504 for half an hour. `release.yml` run 42396902941 published `v0.1.0` with all four assets |
| SX-004 Flavors and signing | Partial | `dev`/`prod` flavors; prod builds. Release keystore is the owner's (`docs/RELEASE.md`) |
| SX-005 Localization scaffold | Done | ARB en/so/ar, `flutter gen-l10n`, RTL widget test |
| SX-006 Logging and diagnostics | Partial | `SxLog` ring buffer + `Redactor` with tests; Diagnostics sheet shows the export |
| SX-007 Error handling and safe boot | Not started | — |
| SX-008 Feature flags | Partial | typed `FeatureFlags` in `sx_core` with tests |
| SX-901 Theme tokens | Done | `app/lib/design/tokens.dart` + `app/test/contrast_test.dart` |
| SX-904 Brand assets | Done | `tools/gen_brand_assets.py`: adaptive icon + monochrome layer, notification icon, Android 12 splash mark, `.ico` 16–256 px |
| SX-905 Fonts | Done | Bricolage Grotesque + Readex Pro bundled, `FontVariation` weights, no runtime fetching |
| SX-902 Component library | Partial | Button/chip/avatar/PeerTile/ChatBubble/SignalBars/RadarView/EmptyState/SxRow/StatusPill exist; no `/dev/gallery`, no goldens |
| SX-101 Identity and safety number | Partial | deterministic safety number + rotating peerTag with tests; key storage needs the plugin |
| SX-104 Framing and reassembly | Done (pure Dart) | fragment round trips, gap/oversize/empty errors, hostile length prefix, fuzz-ish cases |
| SX-106/109 Outbox + FakeTransport | Partial | ordering, dedupe, 1-2-4-8-16-30 s backoff, JSON persistence, lossy link, end-to-end receipt in the app test |
| SX-107 Priority scheduler | Partial | `Outbox.due(msgType:)` filter with a test; no frame-level interleaving yet |

## Known issues

- The universal APK is 54 MB because it carries three ABIs; the plan budget is
  30 MB for an arm64 APK. The per-ABI arm64 build is the one to measure (SX-1103).
- The release APK is signed with the **debug** key so it can be sideloaded. Real
  signing is SX-004, human-owned.
- Icon tree-shaking prints a CupertinoIcons notice; the app uses Material icons
  only and the build succeeds. Clean up with SX-902.
- The CI screenshot is the first frame only: onboarding, the radar and a chat
  are still unverified on Windows.
- Demo peers and messages are in memory: a restart loses them (SX-301).
- `docs/PLAN.md` is a digest of the owner's brief, not the verbatim original.
- No crash recovery, no app lock, no message requests, no files: those are later
  epics and are honestly absent from the UI (the attach button says so).

## Next

1. Owner: two real phones for SX-010/SX-012; run MT-03 and MT-09 and paste logs.
2. SX-007 and SX-008 completion, then EP-02: SX-102 Noise, SX-105 session,
   SX-110 LinkManager, SX-103 protobuf codegen.
3. EP-03 the Kotlin radio plugin (SX-201 … SX-206), which is what turns this
   shell into a messenger.
4. SX-802/803/804 for the desktop target on a Windows machine or in CI.
