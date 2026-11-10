# Copiva

**A fast, native clipboard history manager for macOS.**

[Русский](README.ru.md) · [Roadmap](docs/ROADMAP.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)

> **Status: M0 accepted / early development.** This repository contains a buildable menu-bar app scaffold, not a functional clipboard manager yet. The current release is 0.0.1.

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

## 0.0.1

[Download 0.0.1](https://github.com/StanleyLl0yd/Copiva/releases/tag/v0.0.1) for macOS 26+, Apple Silicon and Intel. It contains the existing menu-bar scaffold for launch/menu/Quit testing; clipboard history is not implemented. The app is ad-hoc signed without Developer ID signing or Apple notarization. See the release notes for installation and the issue #2 acceptance checklist.

## Development

- macOS 26+ and Xcode 26+ (Swift 6.2+).
- Swift Package Manager starter project using SwiftUI and AppKit.

```sh
swift build
swift test
swift run Copiva
```

The current `.app` is a development scaffold with an ad-hoc signature. Developer ID signing, Apple notarization and DMG packaging belong to later milestones.

## License

[MIT](LICENSE). Copyright (c) 2026 StanleyLl0yd.

Future app packages target Apple Silicon (arm64) only, as selected by the owner. The already published 0.0.1 package retains its verified universal binary.
