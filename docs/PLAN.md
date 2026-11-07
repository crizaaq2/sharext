# ShAre XT — Master Plan (agent-facing digest)

This file is the working source of truth for agents. It is a faithful digest of the
owner's 57 KB brief (v1.1, 7 November 2026); every rule, identifier, ticket id and
number below comes from it unchanged. Where this digest is shorter than the original,
the original still wins: ask the owner for the paragraph you need.

ShAre XT shares text, links, emojis, stickers and any file (photos, video, APK, …)
directly between nearby phones and computers over Bluetooth. No internet, no
accounts, no servers, no analytics.

Platforms for 1.0: Android 8+ (API 26) and Windows 10/11. After 1.0: iPhone, macOS,
Linux.

## 0. Somali summary (for the owner)

ShAre XT waa app-ka fariimaha iyo faylasha ee ka shaqeeya Bluetooth oo keliya —
internet looma baahna. Laba telefoon oo isu dhow (qiyaastii 10 m) ayaa si toos ah
isku xirma, fariimaha-na si sir ah ayay u gudbaan (Noise encryption). Lama baahna
account, lambar telefoon, server ama analytics. Fariin kasta waa la kaydiyaa ka hor
intaan la dirin, marka xiriirku go'o ayay si otomaatig ah ugu noqonaysaa. App-ka oo
xiran (laakiin aan la force-stop) wuxuu fariimaha ku soo bandhigaa notification.

## 1. Product

Core flow: first launch explains and asks Bluetooth + notifications; main screen shows
the people around you; tapping a person opens a chat; if that device is unreachable
the app says so and never pretends to send; both sides send text, links, emojis,
stickers and files; the same works phone to computer.

Perf targets (targets, replaced by SX-011 measurements): photo 3 MB ≈ 30 s at
100 KB/s, video 25 MB ≈ 4 min, file 100 MB ≈ 17 min. Show size and ETA above 5 MB,
confirm above 25 MB. Images compressed to about 300 KB by default. Every transfer is
resumable. Text frames pre-empt file frames. Range about 10 m indoors. Design limit
5 simultaneous BLE links.

Releases: R0 radio spikes → R1 Hello (text) → R2 Files → R3 Desktop → R4 Polish →
R5 1.0 → R6 after 1.0 (iPhone/macOS/Linux, Turbo, groups, relay).
Not in 1.0: accounts, cloud backup, calls, groups, any internet fallback.

## 2a. Closed-app delivery (v1.1 headline requirement)

"Closed" is not one state. Use these names in code, tests, tickets and copy:

| State | What the person did | Our code | Reachable |
|---|---|---|---|
| R1 On screen | App open | Running | Yes |
| R2 Background | Switched away or Home | Keep ready service running | Yes |
| R3 Idle | Screen off or locked, Doze | Service running (brand dependent) | Yes, measure per brand |
| R4 Swiped away | Removed from recents | Service survives on stock Android, `stopWithTask` false | Yes on stock; brand dependent |
| R5 Process dead | Killed by system or brand manager | Not running; system-owned BLE scan can wake it (SX-1306) | Only after wake-up |
| R6 Stopped | Force stop, or installed and never opened | Nothing can run until opened once | No |
| R7 Bluetooth off | Radio off | Service alive, radio off | No |
| R8 Not installed | — | — | No (invite flow) |

Mechanisms: keep ready foreground service (type `connectedDevice`) hosting
advertiser + GATT server + scanner + Dart engine; local notifications posted from
native code the headless engine can call; a receiver only needs to advertise
(no scan, no location permission); a revival path via
`BluetoothLeScanner.startScan(filters, settings, PendingIntent)` which keeps running
after the process dies. Rejected: FCM/push, Companion Device Manager presence.

Say plainly: a force-stopped app, or an app never opened, runs nothing until the
person opens it once; the message stays queued and the sender is told the truth.

Targets (replace with SX-018): notification within 8 s of Send in R2 to R4 at p90,
within 15 s after a wake-up in R5, battery inside 2 % per hour in Smart mode.

## 3. Architecture

Flutter (stable, Dart 3) + Material 3 base with custom components; Riverpod; go_router.
`sx_core` pure Dart (protocol, crypto, sessions, transfers, models), no Flutter.
Radio is a federated plugin: Kotlin (Android), C++/WinRT (Windows), Pigeon bridge.
Storage SQLite/Drift + SQLCipher, files on disk, keys in secure store. Crypto
Noise_XX_25519_ChaChaPoly_SHA256 through a vetted library. Wire format Protobuf.
CI builds APK and Windows build on every push.

ADR-01 Flutter over native-per-platform. ADR-02 BLE is the universal transport.
ADR-03 L2CAP when both sides support it, else GATT, behind one `Link` byte stream.
ADR-04 No OS pairing or bonding. ADR-05 identity = long-term X25519 key, TOFU +
safety number/QR. ADR-06 persist before send; receiver ACKs after persisting.
ADR-07 long-lived engine (Android foreground service, Windows tray).
ADR-08 FakeTransport so agents can test everything except the air interface.
ADR-09 real-device truth: no radio ticket Done without an MT log.
ADR-10 accelerators behind the same `Link` interface and feature flags.

Layout:

```
app/                      Flutter app: lib/features/*, lib/design/, lib/l10n/
packages/sx_core/         pure Dart: protocol, framing, identity, outbox, models
packages/sx_radio*/       radio API, platform interface, android, windows
packages/sx_testing/      FakeTransport + N-device harness  (today inside sx_core)
docs/                     PLAN.md STATUS.md DESIGN.md PROTOCOL.md adr/ qa/
tools/                    build scripts, icon generation
```

Key interfaces: see `packages/sx_core/lib/src/transport.dart`.

## 4. Protocol SLP/1

Frozen identifiers (see `packages/sx_core/lib/src/constants.dart`):

- Service UUID `B7F4E0D2-3C1A-4E8B-9A52-6D0C1F7E4A93`
- INFO `…4A94` (read), PSM `…4A95` (read), RX `…4A96` (write without response),
  TX `…4A97` (notify)

Advertisement carries the service UUID only; scan response (where the platform
allows it) adds service data `[version:1][flags:1][peerTag:6]`, peerTag = first 6
bytes of HMAC-SHA256(key = peer public key, msg = "sx-tag" + floor(unixTime/900)).
Scanners always filter by service UUID. A device without service data is resolved by
a short GATT read of INFO (protobuf PeerInfo), one at a time, with backoff, cached.

Connection: connect → MTU 517, 2M PHY, high priority → read INFO/PSM → L2CAP if
both support it else GATT → Noise_XX (static key = identity; changed key = block and
show "Security code changed") → HELLO → Ready → flush outbox. Dual link: keep the one
initiated by the peer with the smaller public key.

Framing: GATT fragments carry one header byte (bit0 START, bit1 END, bits 2–7
sequence); a gap aborts the link. Session frames `[len:u16 BE][Noise ciphertext]`,
plaintext ≤ 16 KB, plaintext is protobuf Envelope {fixed64 id; MsgType type;
fixed64 ts_ms; bytes body}. Unknown fields/types are ignored.

Types: HELLO, TEXT, STICKER, RECEIPT, TYPING, FILE_OFFER, FILE_ACCEPT, FILE_REJECT,
FILE_DATA, FILE_ACK, FILE_DONE, FILE_CANCEL, FILE_RESUME, PING, PONG, BYE, ERROR.
Reserved: REACTION, EDIT, DELETE.

Reliability: UUIDv7 ids; persist then send; receiver persists then ACKs; duplicates
dropped by id. Status ladder queued → sent → delivered → read (optional) → failed.
Retry backoff 1, 2, 4, 8, 16, 30 s while visible. PING after 10 s idle, dead after
25 s silence. Scheduler priority control → text → bulk; one file transfer per link.

Files: FILE_OFFER (name, size, mime, kind, ≤ 8 KB WebP thumbnail), FILE_DATA
(≤ 16 KB, 64–256 KB unacknowledged), FILE_ACK every 32 KB, FILE_RESUME, FILE_DONE
with SHA-256. Auto-accept only known contact + image + ≤ 2 MB. Executables and APKs
never auto-accept.

## 5. Security and privacy

Threats covered: passive sniffing, MITM at first contact, spam/file bombs, malicious
files, tracking (rotating peerTag), stolen phone, malformed frames (size caps,
fuzzing). No accounts, servers, analytics or ads. Logs stay on device, redacted.
At rest SQLCipher; keys in Android Keystore / Windows DPAPI. Reset identity → new
key, contacts see "Security code changed".

Permissions: Android 12+ BLUETOOTH_SCAN (neverForLocation), BLUETOOTH_ADVERTISE,
BLUETOOTH_CONNECT; Android 8–11 BLUETOOTH, BLUETOOTH_ADMIN (maxSdk 30) + location
(services ON; we never read location); Android 13+ POST_NOTIFICATIONS; foreground
service type connectedDevice (+ FOREGROUND_SERVICE_CONNECTED_DEVICE on 14+); camera
only for the safety QR; files via the system picker. Windows: Bluetooth capability.

Never use the Bluetooth logo or wordmark in our identity.

## 6–7. Sonar design system and the Wadaag lens

Dark is default: tideInk #06222B base, reef #0D3441 raised, lagoon #22D1C6 primary
and outgoing bubble (tideInk text on it), sun #FFB43A accent/peer ring/badge,
foam #EAF7F6 text, mist #8FB4B8 secondary text, coral #FF6B5B danger.
Light: background #F2FAF9, surface #FFFFFF, text #072229, primary lagoonDeep #087A77,
accent text sunDeep #9A5B00, danger #C2352A.
Type: Bricolage Grotesque (display 600–800) + Readex Pro (body, Latin + Arabic), both
bundled, runtime fetching disabled. Scale: display 34/38, title 22/28, body 16/24,
chat 16/22, label 14/20 (500), caption 12/16. Bubbles max 78 % on phones, 560 px on
desktop. Radius: bubbles 20 (6 on tail), tiles 16, inputs 24, sheets 28 top, buttons
and chips round, avatars circular; 4 dp grid; 48 dp targets.
Motion: snappy 500/32, smooth 300/28, lens 220/18; 120/240/420 ms; signature moment
= tapping a blip slides its ring over yours and lights the lens; radar ping 2.4 s;
reduced motion = fades ≤ 120 ms. Layout: phone bottom nav (Around you, Chats, You);
≥ 840 px rail + list + chat; ≥ 1200 px adds info pane.

Logo: two interlocking rings, the overlap (lens) is the product. Master SVG in the
owner's brief; assets are generated by `tools/gen_brand_assets.py` from the same
geometry. Never recolour, shadow, gradient it, or use the Bluetooth logo.

## 8–9. Backlog and sprints

EP-00 Foundations (Sprint 0): SX-001 repository, SX-002 agent docs, SX-003 CI,
SX-004 flavors and signing, SX-005 localization, SX-006 logging, SX-007 error
handling, SX-008 feature flags.
EP-01 Radio spikes: SX-010 BLE hello, SX-011 throughput, SX-012 background survival,
SX-013 headless core, SX-014 Windows radio, SX-015 bridge throughput, SX-016 Noise
in Dart, SX-017 go/no-go.
EP-02 Core: SX-101 identity/safety number, SX-102 Noise, SX-103 protobuf, SX-104
framing, SX-105 session, SX-106 reliable messaging, SX-107 scheduler, SX-108 trust,
SX-109 transport + FakeTransport, SX-110 LinkManager.
EP-03 Android radio: SX-201 Pigeon API … SX-210 conformance suite.
EP-04 Data: SX-301 DB v1 … SX-305 export.
EP-05 Onboarding: SX-401 splash/onboarding/profile … SX-407 message requests.
EP-06 Messaging: SX-501 conversation list … SX-509 presence/typing.
EP-07 Files: SX-601 attach sheet … SX-611 multi-file queue.
EP-08 Rich content: SX-701 stickers, SX-702 sticker pack, SX-703 voice notes,
SX-704 custom stickers, SX-705 reactions.
EP-09 Windows: SX-801 radio (a/b/c), SX-802 adaptive layout, SX-803 window and tray,
SX-804 installer, SX-805 readiness wizard, SX-806 cross-device test, SX-807 macOS/Linux.
EP-10 Design: SX-901 tokens, SX-902 components + gallery, SX-903 motion/haptics,
SX-904 brand assets, SX-905 fonts, SX-906 accessibility, SX-907 translation review.
EP-11 Settings: SX-1001 … SX-1006 diagnostics.
EP-12 QA/release: SX-1101 … SX-1108 (incl. SX-1107 name clearance, human).
EP-13 After 1.0: SX-1201 … SX-1207 (SX-1302 notifications from headless engine,
SX-1304 brand battery guide, SX-1306 revival path, SX-1309 Windows tray only).

Sprint 0 exit: Go/No-Go signed, repo and CI work, tokens exist.

## 10–11. Tests and risks

Layers: unit (core ≥ 90 %), contract (same suite vs FakeTransport and real radios),
scenario with fault injection, fuzz of frame parser and protobuf, golden UI tests,
integration on devices, manual tests.
Device matrix: A low-end Android 8/9; B mid-range 10–12 (Tecno/Infinix/itel/Redmi);
C Samsung 13/14; D newest Android; E Windows 10; F Windows 11; G USB BT 5 dongle.
Pairs A–B, B–C, C–D, B–E, D–F, D–G.
Manual tests MT-01 … MT-30 are listed in `docs/qa/README.md`.
Risks: slower Bluetooth than hoped (measure, then Turbo), OEM task killers, GATT
quirks, Windows adapters without the peripheral role, engine lifetime in a service,
agents claiming success without hardware, Play policies, name conflicts, iPhone later,
lost keystore or identity key.

## 12–15. Agent rules, kickoff, release, assumptions

Agent rules live in `AGENTS.md`. Release checklist: all P0 done, MT-01…MT-30 pass,
coverage gates green, security review closed, name clearance signed, version bumped,
changelog, tag, CI builds signed APK + Windows installer, clean-install test, store
listing and privacy policy in en/so/ar, rollback = keep the previous APK and
installer online. Application id `com.sharext.app` (never change after release).
Languages en, so, ar.
