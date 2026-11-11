# Architecture

## Implemented foundation

The SwiftPM executable uses SwiftUI and AppKit for a menu-bar window and Quit. M0 is accepted in issue #2. The runtime does not yet observe the clipboard or connect a picker to persistence.

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

## Remaining product integration

- Observe NSPasteboard changes with explicit consent, sensitive-type filtering, bounded reads and app-write suppression.
- Provide a configurable native global shortcut and keyboard-first picker.
- Guard intended-app/focus insertion and request Accessibility only on explicit paste intent; offer safe Copy when unavailable.
- Preserve supported original representations, rich text, images and file references through later adapters and managed payload files.
- Add pinned retention independent of ordinary cleanup, caret positioning/fallbacks, application exclusions and the remaining roadmap gates.
