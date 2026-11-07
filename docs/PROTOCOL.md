# SLP/1 — ShAre Link Protocol

Source: PLAN section 4. Constants and code: `packages/sx_core/lib/src/`.

## Identifiers (frozen after the first public release)

| Name | UUID |
|---|---|
| Service | `B7F4E0D2-3C1A-4E8B-9A52-6D0C1F7E4A93` |
| INFO (read) | `…4A94` |
| PSM (read) | `…4A95` |
| RX (write without response) | `…4A96` |
| TX (notify) | `…4A97` |

## Discovery

The advertisement carries the service UUID only. Where the platform allows a
scan response, it adds service data `[version:1][flags:1][peerTag:6]` where

```
peerTag = HMAC-SHA256(key = peer public key, msg = "sx-tag" || floor(unixTime/900))[0..6]
```

Contacts recompute the current and neighbouring windows; strangers cannot link
your tags over time. Scanners always filter by the service UUID (Android blocks
unfiltered scans with the screen off). A device without service data is resolved
with one short GATT read of INFO (protobuf PeerInfo: public key, display name,
capability bits, protocol range, PSM), one device at a time, with backoff and a
cache. Windows peripherals cannot add service data, so they always take that path.

## Connection

1. Tap a person, or auto-connect for a contact with queued items.
2. Connect; request MTU 517, 2M PHY, high priority for bulk.
3. Read INFO and PSM; open L2CAP when both sides support it, else subscribe to
   TX and write to RX.
4. Noise_XX over the link. The peer's static key is its identity. A changed key
   blocks the link and shows "Security code changed".
5. HELLO (name, avatar hash, capabilities) → Ready → flush the outbox.
6. Two links to the same peer: keep the one initiated by the peer with the
   smaller public key, close the other.

## Framing

GATT fallback: `1 header byte + chunk`, header bit 0 START, bit 1 END, bits 2–7
sequence (mod 64). A gap aborts the link. Session frames:
`[len:u16 big-endian][Noise ciphertext]`, plaintext at most 16 KB, plaintext is a
protobuf Envelope `{fixed64 id; MsgType type; fixed64 ts_ms; bytes body}`.
Unknown fields and types are ignored. HELLO carries proto_min/proto_max.

Types: HELLO, TEXT, STICKER, RECEIPT, TYPING, FILE_OFFER, FILE_ACCEPT,
FILE_REJECT, FILE_DATA, FILE_ACK, FILE_DONE, FILE_CANCEL, FILE_RESUME, PING,
PONG, BYE, ERROR. Reserved: REACTION, EDIT, DELETE.

## Reliability

UUIDv7 ids. Sender persists first, then sends. Receiver persists, then sends
RECEIPT delivered. Duplicates are dropped by id. Ladder: queued → sent →
delivered → read (optional) → failed. Retry backoff 1, 2, 4, 8, 16, 30 s while
the peer is visible; reconnect when it is sighted again. PING after 10 s idle,
link dead after 25 s of silence. Scheduler priority control → text → bulk, one
file transfer per link in v1.

## Files

FILE_OFFER (id, name, size, mime, kind, ≤ 8 KB WebP thumbnail) → FILE_ACCEPT →
FILE_DATA (≤ 16 KB frames, 64–256 KB unacknowledged) → FILE_ACK every 32 KB with
the contiguous offset → FILE_RESUME after reconnect → FILE_DONE with SHA-256.
Auto-accept only for a known contact, an image and at most 2 MB. Executables and
APKs never auto-accept; the receiver sees a preview before accepting.

## Limits in code

`Slp1.maxPlaintext` 16 KB, `Slp1.maxFrame` 64 KB (the hard cap on any allocation
for unauthenticated input), 64 fragments, 5 concurrent links, 15 s sighting
staleness. Fuzz and oversize tests live in `packages/sx_core/test/framing_test.dart`.
