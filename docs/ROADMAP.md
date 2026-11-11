# Copiva roadmap

Checkboxes track accepted milestone work. Source implementation can be ahead of acceptance; CI alone does not complete an item.

**Milestone acceptance:** each milestone has a full repository-wide, two-pass audit, safe-refactoring, security and code-review exit gate, documented in `AGENTS.md` and `docs/agent/AUDIT_REFACTOR.md`. Do not mark a milestone accepted on CI alone.

## M0 — Repository and bootstrapping
- [x] SwiftPM + SwiftUI menu-bar app skeleton
- [x] Tests and macOS CI workflow
- [x] Bilingual README, license, contributing, security policy
- [x] Protected default branch: PR-only, strict exact-head CI, linear/squash history
- [x] Initial Dependabot alerts/updates, secret scanning/push protection and Swift CodeQL setup (historical; current settings verification remains in exit issue #2)
- [x] Run and validate the scaffold on an actual Mac (owner acceptance recorded 2026-11-10)
- [x] Complete M0 two-pass repository-wide exit audit and record evidence

M0 runtime acceptance is confirmed by the owner. The complete exit record is in `docs/agent/M0_EXIT_2026-11-10.md`; final protected-main verification and milestone closure are recorded in issue #2. Release versions are numeric only; future distribution targets Apple Silicon arm64.

## M1 — First usable clipboard history

Text persistence/capture/menu and the keyboard picker/paste path are implemented in the M1 PR series. Exit issue #6 tracks final protected-main verification and real-Mac acceptance; M1 remains open until that gate passes.
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
- [ ] Owner-approved canonical app icon and verified raster resource pipeline
- [ ] Protect immutable version tags, release provenance and signing environment
- [ ] Build signed and notarized `.app` / DMG
- [ ] Release verification, user documentation and installation test

Out of scope for the first stable release: cloud sync, OCR, advanced collections.
