# Manual tests (real devices only)

ADR-09: no ticket that touches the radio is Done without a human running the
matching test here and pasting the log. Two real Android phones, and from Sprint
4 one Windows laptop with Bluetooth. Never an emulator, never one phone.

Every log comes from Diagnostics → Share logs. Paste the file name and the result
into `docs/qa/results.md`.

## Device matrix

A low-end Android 8/9 · B mid-range Android 10–12 (Tecno, Infinix, itel, Redmi) ·
C Samsung 13/14 · D newest Android (15/16) · E Windows 10 · F Windows 11 ·
G desktop PC with a USB Bluetooth 5 dongle.
Pairs: A–B, B–C, C–D, B–E, D–F, D–G.

## Tests

| Id | What the tester does | Pass when |
|---|---|---|
| MT-01 | First launch, follow the primer | Both permissions granted, Keep ready on |
| MT-02 | Turn Bluetooth off and on mid-session | App recovers, tells the truth while off |
| MT-03 | Both phones on the Around you screen | Both see each other within 5 s |
| MT-04 | Tap a person | Chat opens with a visible connect progress |
| MT-05 | Send to a phone with no app, or force-stopped | Sheet offers Invite / Keep message / Close, message queued |
| MT-06 | Send 100 text messages | All arrive, in order, exactly once |
| MT-07 | Airplane mode on, send, off again | Message queued, delivered after radio returns |
| MT-08 | Walk out of range and back | Chip flips to Out of range, then In range, delivery resumes |
| MT-09 | Background 30 min, screen off | Notification per message; state R2/R3 recorded |
| MT-10 | 3 MB photo | Arrives, SHA-256 matches, thumbnail before accept |
| MT-11 | 25 MB video | Confirmation shown, ETA updates, arrives |
| MT-12 | 100 MB file | Arrives, RAM under 100 MB during transfer |
| MT-13 | Disconnect mid-file, reconnect | Resumes at the persisted offset |
| MT-14 | Kill the app mid-file, restart | Transfer finishes, nothing duplicated |
| MT-15 | Send an APK | Receiver taps to accept, then opens it deliberately |
| MT-16 | Stickers and emoji | Render identically on both platforms |
| MT-17 | Tap a link, and a look-alike domain | Real domain shown, warning on look-alike |
| MT-18 | Reset identity on one phone | Other phone shows Security code changed |
| MT-19 | Flood from a stranger | Rate limit silences after 5 offers/minute |
| MT-20 | Android ↔ Windows chat | Both directions, tray keeps the radio alive |
| MT-21 | Android → Windows 25 MB file | Arrives with matching SHA-256 |
| MT-22 | Windows → Android resume | Resumes after closing the window to the tray |
| MT-23 | Message while the window is in the tray | Toast posted |
| MT-24 | Install and uninstall on clean Windows 10 and 11 | Both work, no leftover service |
| MT-25 | Arabic and RTL | Layout mirrors, nothing clipped |
| MT-26 | TalkBack | A user can send a message unaided |
| MT-27 | Low storage | Accept refused with a clear message |
| MT-28 | One hour idle battery | Inside 2 %/hour in Smart mode |
| MT-29 | Five people at once | All five links work, no connection storm |
| MT-30 | Reboot the phone | Keep ready comes back, messages still queued |
| MT-31 | You → Files, choose one folder, then drop a photo/PDF into it with the phone's file manager and reopen Files | The same folder name shows, the dropped file is listed, and the list survives a restart. One phone is enough; no radio involved |

## Results template (`results.md`)

```
## MT-06 — pass
Phones: Infinix Hot 12 (Android 12), Samsung A54 (Android 14)
Log: sharext-log-2026-11-07-1822.txt
Notes: all 100 arrived, order preserved, ticks went queued → sent → delivered.
```
