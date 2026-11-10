# Architecture notes (planned, not implemented)

- Swift 6.2, SwiftUI UI and AppKit for global input, pasteboard and floating panel.
- Monitor `NSPasteboard` with change detection, and protect against self-generated writes.
- Persist metadata in SQLite with FTS5, binary representations as managed files.
- Store multiple pasteboard representations per clip for original/plain-text paste.
- Keep pinned clip retention completely separate from ordinary history cleanup.
- Prefer positioning the picker at the text caret when accessible, with a safe fallback.
- Do not write clipboard payloads to diagnostics. Never collect password-manager content if it is marked confidential.

This document describes intended direction only. Technical choices will be validated as features are implemented.
