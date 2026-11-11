# Architecture

## Implemented foundation

The SwiftPM executable uses SwiftUI and AppKit for a menu-bar history window. M0 is accepted in issue #2. CopivaMac owns the platform clipboard adapter and observable history session; CopivaCore owns persistence. A native global shortcut and dedicated keyboard picker remain separate integration work.

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

## Remaining product integration

- Provide a configurable native global shortcut and keyboard-first picker.
- Guard intended-app/focus insertion and request Accessibility only on explicit paste intent; offer safe Copy when unavailable.
- Preserve supported original representations, rich text, images and file references through later adapters and managed payload files.
- Add pinned retention independent of ordinary cleanup, caret positioning/fallbacks, application exclusions and the remaining roadmap gates.
