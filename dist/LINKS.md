# Download links (v0.1.0, Sprint 0 test build)

Public, no sign-in needed. Anyone with a link can download; these are test builds,
not the 1.0 release.

| Build | Link | Size | SHA-256 |
|---|---|---|---|
| arm64 (modern phones) | https://files.catbox.moe/0cqx2r.apk | 20.4 MB | `5ce1fec3c8bbbfae362fe1e181c2449fae3c4bb179f251c692d3690def147d56` |
| universal (any phone) | https://files.catbox.moe/dp5ebl.apk | 52 MB | `0aa102c469da8e417f9589afe6e18d44c5b7769cc71a67aef432de186862b2f9` |
| arm32 (Android 8–10) | https://files.catbox.moe/qkfav0.apk | 18 MB | `d6a7cdb04e8b41ad75ddcae69dfdb4307f12d1271b04b0d7f3b0c04b5ff23e73` |

The arm64 upload was downloaded again and its SHA-256 matched the local file, so the
hosted bytes are identical to the ones built here.

## Install

1. Open the link on the phone.
2. Allow "Install unknown apps" for the browser or file manager.
3. Install. Play Protect may warn: the APK is signed with the debug key on purpose
   (real release signing is SX-004, owner's keystore).
4. Open ShAre XT: lens splash, three slides, then Around you.

## Honest state of this build

No Bluetooth plugin yet (EP-03). Messages stay queued and the chat says
"Waiting for Axmed's phone". The radar, chat UI, three languages (so, en, ar with
RTL), theme switching and diagnostics are real.

Windows: the EXE must be built on Windows or in CI (`tools/build_windows.ps1`,
`.github/workflows/ci.yml`), see `docs/RELEASE.md`.
