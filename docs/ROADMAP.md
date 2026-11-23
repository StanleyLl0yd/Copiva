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

Text capture, local history, and the keyboard picker are implemented. The immediate priority is to verify capture, search, insertion into the intended field, and focus restoration in real macOS apps. When Copiva cannot verify the destination or lacks Accessibility permission, the selected item should still be available to paste manually. [Issue #6](https://github.com/StanleyLl0yd/Copiva/issues/6) tracks acceptance.
- [ ] Observe supported clipboard changes without recording app-generated writes
- [ ] Persist ordinary text history in SQLite
- [ ] Quick picker; assignable global keyboard shortcut
- [ ] Instant text search, navigation, paste

## M2 — Full-fidelity clipboard
- [ ] Add a single Pinned section. Clips stay pinned across restarts, upgrades, retention limits, and ordinary history cleanup until the user unpins or explicitly deletes them.
- [ ] Keep supported original text representations (plain text, RTF, and HTML). Use Return to paste with the original formatting where supported, Shift-Return to paste as plain text, and Command-Return to copy.
- [ ] Capture and insert supported images and file references, with the same checks for the intended destination.

## M3 — UX and localization
- [ ] Open the picker near the text caret. Fall back to the pointer or a visible position on the current screen when the caret is unavailable.
- [ ] Verify keyboard navigation and focus restoration with the caret picker. Put secondary actions such as pinning and deleting in a keyboard-accessible actions menu.
- [ ] Add compact previews: a few lines of text, an image thumbnail, or a file name. Open a larger preview on request.
- [ ] Add quick filters for text, links, images, and files once the corresponding types are captured.
- [ ] Preferences, themes, RU/EN localization and launch-at-login

## M4 — Privacy and reliability
- [ ] Sensitive pasteboard marker support and application exclusions
- [ ] History cleanup policy, limits and large-clip behavior
- [ ] Persistence recovery, concurrency and failure-path tests
- [ ] No sensitive clipboard payloads in logs
- [ ] Evaluate encryption for local history, including its search index and supporting files. Account for key recovery and upgrades before choosing an approach.

## M5 — First stable release
- [ ] Owner-approved canonical app icon and verified raster resource pipeline
- [ ] Protect immutable version tags, release provenance and signing environment
- [ ] Build signed and notarized `.app` / DMG
- [ ] Release verification, user documentation and installation test

## Product references and later ideas

[Raycast Clipboard History](https://manual.raycast.com/clipboard-history) is a reference for keyboard actions and type filters. [Paste on Mac](https://pasteapp.io/help/paste-on-mac) and its [Pinboards](https://pasteapp.io/help/organize-with-pinboards) are references for previews and pins that outlive ordinary history. Copiva’s main interaction is a compact picker at the current point of work.

Cloud sync, OCR, advanced collections, and sequential paste are outside the scope of the first stable release. Revisit them when everyday use reveals a concrete need.
