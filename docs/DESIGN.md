# Design: Sonar (2027) and the Wadaag lens

Source: PLAN sections 6 and 7. The implementation lives in
`app/lib/design/tokens.dart`, `app/lib/design/theme.dart` and
`app/lib/design/components/`.

## Why this look

Two ranges that overlap is the product. The vocabulary is sonar, the palette
echoes the Indian Ocean coast, and boldness is spent in exactly one place: the
radar and the lens (two rings overlapping when you connect). Everything else
stays quiet. Blue/green chat identities were rejected on purpose (Telegram,
Signal, WhatsApp): this is not another messenger, it is a local radio.

## Tokens (never hard-code a colour outside `tokens.dart`)

| Role | Dark (default) | Light |
|---|---|---|
| base | tideInk `#06222B` | `#F2FAF9` |
| raised / incoming bubble | reef `#0D3441` | `#FFFFFF` |
| primary / outgoing bubble | lagoon `#22D1C6` | lagoonDeep `#087A77` |
| text on primary | tideInk | white |
| accent, peer ring, badge | sun `#FFB43A` | sunDeep `#9A5B00` |
| text | foam `#EAF7F6` | `#072229` |
| secondary text | mist `#8FB4B8` | `#4F7176` |
| danger | coral `#FF6B5B` | `#C2352A` |

Rules: no gradient washes, no grey drop shadows (separate layers by tone),
focus ring 2 px lagoon with 2 px offset. `app/test/contrast_test.dart` fails the
build below 4.5:1 on every text pair.

## Type

Bricolage Grotesque (display 600–800) and Readex Pro (body, Latin + Arabic),
both bundled under `app/assets/fonts` because the app is offline. Runtime font
fetching is disabled. Scale: display 34/38, title 22/28, body 16/24, chat 16/22,
label 14/20 (500), caption 12/16. Bubbles max 78 % on phones, 560 px on desktop.

## Shape, space, motion

Radius: bubbles 20 (6 on the tail corner), tiles 16, inputs 24, sheets 28 on the
top corners, buttons and chips fully round, avatars circular. 4 dp grid, 48 dp
touch targets.

Motion answers an action. Springs snappy 500/32, smooth 300/28, lens 220/18;
durations 120/240/420 ms. Signature moment: tapping a blip slides its ring over
yours, the lens lights up, the chat opens. Radar ping loop 2.4 s, paused when
idle. Reduced motion: fades of at most 120 ms and static rings (implemented in
`RadarView` and the splash).

## Layout

Phone: bottom navigation with Around you / Chats / You. Desktop from 840 px: a
rail plus the page. From 1200 px an info pane is added (SX-802, not yet built).

## Brand assets

`tools/gen_brand_assets.py` regenerates every raster from the frozen SVG
geometry: launcher icons (mdpi…xxxhdpi), adaptive foreground + monochrome layer,
Android 12 splash mark, the white notification icon and the Windows `.ico`
(16–256 px). Never recolour, shadow, gradient, redraw the mark, or use the
Bluetooth logo.

## Copy

Sentence case, plain verbs, no ALL-CAPS labels, no eyebrow labels, no A · B · C
meta strings, no arrows glued to buttons. Errors say what happened and what to do,
and never apologise. An empty screen invites an action. All strings live in ARB
files (en, so, ar) — see `app/lib/l10n/`.
