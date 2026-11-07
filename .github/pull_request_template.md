## Ticket

SX-___ — <title>

## What changed

-

## How it was verified

- [ ] `dart test` in every touched package
- [ ] `flutter analyze` and `flutter test` in `app`
- [ ] Manual test on real devices (MT-__) — paste the log, or write
      NEEDS-DEVICE-TEST and list the numbered steps
- [ ] No new colour, string or dependency outside `tokens.dart`, the ARB files or
      `docs/adr/`

## Risk and rollback

- Blast radius:
- Rollback:

## Checklist

- [ ] `docs/STATUS.md` updated
- [ ] No secrets, keystores or logs with message text
- [ ] Under about 300 changed lines, or split into another PR
