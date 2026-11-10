# Copiva

**A fast, native clipboard history manager for macOS.**

[Русский](README.ru.md) · [Roadmap](docs/ROADMAP.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)

> **Status: M0 / early development.** This repository contains a buildable menu-bar app scaffold, not a functional clipboard manager yet. No releases are available.

Copiva aims to make copying, finding, saving, and pasting feel effortless on macOS, with an independent, compact interface instead of relying on Spotlight.

## Planned capabilities

- Configurable global shortcut and a compact picker near the insertion point, with safe positioning fallback.
- Automatic clipboard history and instant, keyboard-driven search.
- Pin/unpin entries; pinned clips survive restarts and are never auto-deleted.
- Paste with original formatting **or** as plain text, selected from the picker.
- Preserve supported clipboard representations, including rich text and images.
- Configurable retention of ordinary history, independent of pinned items.
- Local-first data processing and privacy controls for sensitive applications.

**These are requirements, not claims about the current build.**

## Development

- macOS 26+ and Xcode 26+ (Swift 6.2+).
- Swift Package Manager starter project using SwiftUI and AppKit.

```sh
swift build
swift test
swift run Copiva
```

The initial SwiftPM executable is a development scaffold. A signed `.app` and DMG packaging pipeline will follow in later milestones.

## License

[MIT](LICENSE). Copyright (c) 2026 StanleyLl0yd.
