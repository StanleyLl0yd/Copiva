# Copiva roadmap

All functionality below is planned unless explicitly marked done.

## M0 — Repository and bootstrapping
- [x] SwiftPM + SwiftUI menu-bar app skeleton
- [x] Tests and macOS CI workflow
- [x] Bilingual README, license, contributing, security policy
- [ ] Run and validate the scaffold on an actual Mac
- [ ] Set up branch protection after a green CI run

## M1 — First usable clipboard history
- [ ] Observe supported clipboard changes without recording app-generated writes
- [ ] Persist ordinary text history in SQLite
- [ ] Quick picker; assignable global keyboard shortcut
- [ ] Instant text search, navigation, paste

## M2 — Full-fidelity clipboard
- [ ] Preserve supported original text representations (plain/RTF/HTML)
- [ ] Original and Plain Text paste actions
- [ ] Capture and insert supported images and file references
- [ ] Pin/unpin with indefinite persistence, independent retention

## M3 — UX and localization
- [ ] Position panel near text caret, with mouse/screen fallback
- [ ] Avoid focus and click interference; keyboard-first interaction
- [ ] Preferences, themes, RU/EN localization and launch-at-login

## M4 — Privacy and reliability
- [ ] Sensitive pasteboard marker support and application exclusions
- [ ] History cleanup policy, limits and large-clip behavior
- [ ] Persistence recovery, concurrency and failure-path tests
- [ ] No sensitive clipboard payloads in logs

## M5 — First stable release
- [ ] Build signed and notarized `.app` / DMG
- [ ] Release verification, user documentation and installation test

Out of scope for the first stable release: cloud sync, OCR, advanced collections.
