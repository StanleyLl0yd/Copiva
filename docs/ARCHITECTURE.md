# Architecture

## Implemented foundation

The SwiftPM executable uses SwiftUI and AppKit for a menu-bar history window. M0 is accepted in issue #2. CopivaMac owns the platform clipboard adapter and observable history session; CopivaCore owns persistence. The native global shortcut and nonactivating keyboard picker use this same session.

## M1 text persistence

CopivaCore now provides an actor-owned HistoryStore and immutable, Sendable TextClip values. It uses the macOS SDK's SQLite3/FTS5 library, without a third-party Swift package. Platform clipboard adapters and UI will call this boundary; the backend alone is not a functional clipboard manager.

- The caller supplies an app-owned directory dedicated to history. It is mode 0700; history.sqlite3 is mode 0600. Reject the selected directory/database symlinks (including dangling database links); canonicalize ancestor aliases with POSIX realpath, then retain SQLite's no-follow flag for the database open.
- Schema 1 uses application_id 0x43505641, append-ordered IDs, exact UTF-8 text and epoch-double copy timestamps (returned values use the persisted precision), plus an external-content FTS5 index with insertion/deletion triggers. Future schema versions, foreign databases and malformed storage fail without reset/replacement.
- WAL and FULL synchronous commits provide SQLite's transaction/recovery guarantees. Recording and ordinary-history pruning are one transaction; explicit remove/clear operations are transactional too; failed cleanup rolls back the insertion. Failed limit changes preserve the previous limit. An unsuccessful rollback closes the connection.
- Payloads are at most 256 KiB of UTF-8. Configurable ordinary-history count is 1–10,000 (default 500), enforced on successful writes/explicit limit changes. Opening preserves existing rows. Results are capped at 200; queries at 512 UTF-8 bytes and 32 words.
- Search matches Unicode word prefixes with accent folding. User input is tokenized into literal words and bound separately from SQL; FTS operators are not accepted as syntax. Punctuation-only queries return no matches.
- Errors expose typed state/numeric SQLite codes, never SQL messages, paths or payloads. Storage is local plaintext, not encrypted. Deletion is not a secure-erasure promise: FTS segments, WAL, filesystem snapshots and SSD behavior need separate consideration.
- There are no pinned items in schema 1. Future pinning requires an explicit compatible migration and retention changes; an old reader must reject that newer schema instead of deleting pinned data.

Regression tests use only synthetic contents and real temporary SQLite databases: reopen identity/Unicode/NUL preservation, search literals, retention/FTS consistency, forced transaction failure, future/foreign/corrupt-file and malformed-record preservation, permissions/symlinks, bounds, explicit deletion/clear, concurrent calls and abrupt SQLite-writer termination before/after commit. Crash fixtures use the platform SQLite CLI with a readiness checkpoint and SIGKILL, exercising actual WAL recovery without production test hooks. Native CI is the source of executed results; do not infer real clipboard/UI acceptance from these backend tests.

## Text capture and menu integration

HistorySession opens the app-owned Application Support/Copiva/History directory, loads saved history while paused, and polls only after consent. Recording is off on first launch; enabling it requires an explanatory confirmation. Consent and the recording choice persist separately. Resume takes a fresh change-count baseline, so existing clipboard data is never imported retroactively. One awaited polling loop prevents a backlog of capture tasks. Search replies carry a generation to prevent stale results replacing newer UI state.

ClipboardMonitor reads a single UTF-8 text item, verifies the pasteboard change count after reading, skips file references, and consumes each observed change once. It skips known concealed, transient, auto-generated, 1Password and Copiva-generated type markers. Explicit Copy writes a marked item so it is not recaptured. It never restores an old clipboard over a newer copy. Oversize/empty/invalid text is skipped; output is limited to the core's 256 KiB bound. AppKit's data-provider API may allocate or wait before returning data; the post-read byte limit is not a pre-allocation or hard time guarantee.

Excluded bundle IDs are configurable in the menu. Attribution is the foreground app at observation time, not an authoritative producer identity; background producers and rapid focus changes are a platform limitation. An unknown source is skipped when exclusions are configured. Markers/exclusions cannot identify every secret or password manager. No clipboard contents, paths or raw database errors enter diagnostics. Saved text is plaintext local data; no new network or OS permission is requested for capture/copy.

The menu exposes bounded search results, explicit Copy, recording controls, retention choices, exclusions and confirmed history clearing. Storage failures stop capture and preserve files; there is no automatic reset. Clear does not write the clipboard. Tests use private named pasteboards, isolated defaults and synthetic SQLite directories; no test reads NSPasteboard.general or asserts real-app UI acceptance.

## Keyboard picker and paste

A Carbon application-event handler registers a configurable physical key code and modifier combination without Input Monitoring. Settings persist only after a successful registration. Register the new combination before unregistering the previous one; conflicts preserve the old registration. First-launch conflicts retain the handler so a different combination can be assigned. Event-handler context is owned by the main-actor hotkey lifetime and removed at deinitialization. No global key listener records typed characters.

The picker is a nonactivating NSPanel: search stays local, stable clip IDs preserve selection across refreshed results, Up/Down clamp at the edges, Return requests Paste, Command-Return copies, and Escape closes. Marked-text composition is left to the input method. Pointer-based placement clamps to the current screen's visible frame, including negative multi-display origins. Caret placement remains M3. Closing or dismissing the panel does not activate another app.

PasteCoordinator separates permission/focus/event access from action policy for failure-path tests. Opening the picker captures the foreground running application and the original writable, non-secure AX text element only if already trusted; it never prompts. Explicit Paste may prompt for Accessibility. Newly granting permission does not schedule a later paste: reopen the picker and choose again. Missing permission/unverifiable focus keeps the picker open and copies instead. After panel dismissal, a bounded modifier-release wait and repeated AX/process/launch-identity checks protect the original destination. Cancellation/new invocation invalidates pending intent. The marked clipboard write's change count is checked again before posting Command-V; later clipboard changes are not restored or pasted deliberately.

Automatic paste is conservative: applications that do not expose a writable AX text element use Copy/Command-V. Focus checks and event posting are separate OS operations, not an atomic guarantee, and a destination may ignore an event. The UI reports a paste request, not proof of insertion. AX messaging has a per-call timeout. Secure input, permission changes, app switching, IME composition, Spaces/fullscreen, focus restoration and actual insertion require the real-Mac checklist in docs/MANUAL_TESTING.md; synthetic policy tests and Carbon registration tests do not establish those runtime outcomes.

## Remaining product integration

- Preserve supported original representations, rich text, images and file references through later adapters and managed payload files.
- Add pinned retention independent of ordinary cleanup, caret positioning/fallbacks, application exclusions and the remaining roadmap gates.
