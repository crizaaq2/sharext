# ShAre XT: rules for AI agents

Read `docs/PLAN.md` sections 2 to 5 before your first task. One ticket per branch:
`feat/SX-123-short-name`. Commit messages start with the ticket id.

1. Test first. Write the failing test, then the code. Run `flutter analyze` and
   `flutter test` in every touched package before you say done.
2. Never claim Bluetooth works unless a human ran the matching manual test (MT-xx)
   on real devices. If you cannot test it, label the ticket NEEDS-DEVICE-TEST and
   add the steps to `docs/qa/`.
3. Layers: `app` depends on `sx_core`; only `sx_radio` talks to platform code.
   `sx_core` imports no Flutter.
4. No hard-coded colours (use tokens), no hard-coded user-visible strings (use ARB),
   no new dependency without a short note in `docs/adr/` (licence, size, maintenance).
5. Never log message text, keys or file names. Never commit keystores or secrets.
6. Before any UI work load the frontend-design skill if available and follow
   `docs/DESIGN.md`. Avoid the template tells listed there.
7. After each ticket update `docs/STATUS.md`: what changed, how it was verified,
   what is next, known issues.
8. If a requirement is unclear, write the question in `docs/QUESTIONS.md` and
   continue with another ticket.
9. Keep changes small: under about 300 changed lines per pull request; split bigger
   tickets.
10. Definition of done: acceptance criteria met, tests added, analyze clean, docs
    updated, no TODO left in merged code.

## The five rules that outrank everything else

1. **Two real phones.** Bluetooth between two devices cannot be tested on an
   emulator or on a single phone. Every radio ticket needs two real Android phones
   (and from Sprint 4 one Windows laptop with Bluetooth). Tell the owner plainly:
   "I need two phones", which two, and numbered steps. Never claim it works without
   their log (ADR-09).
2. **No internet, no push services.** No Firebase, FCM, Play Services push, servers,
   analytics or any network call. Message notifications are local notifications
   posted by our own background service when a message arrives over Bluetooth.
3. **Background delivery is a headline requirement.** Phone near, Bluetooth on, app
   installed but not on screen: the message must arrive as a notification. Never
   tell the sender "can't be sent" in that case. Honest limits: force-stopped app,
   or installed and never opened (see PLAN section 2a, states R1 to R8).
4. **The logo is final.** Use the SVG in `docs/PLAN.md` section 7 exactly. Do not
   redraw, recolour or restyle it, and never use the Bluetooth logo.
5. **Persist first, send second.** Delivered means the peer persisted it (ADR-06).
   Nothing that touches the radio is Done without a human-run manual test and log.

## Language

Talk to the product owner in the language they write (Somali or English). Keep code,
commits, tickets and docs in English. User-facing strings live in the ARB files
(`en`, `so`, `ar`).
