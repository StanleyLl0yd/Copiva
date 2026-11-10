# Copiva

**Find your way back to what you copied.**

[![License: MIT](https://img.shields.io/github/license/StanleyLl0yd/Copiva)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/StanleyLl0yd/Copiva)](https://github.com/StanleyLl0yd/Copiva/releases/latest)
[![CI](https://github.com/StanleyLl0yd/Copiva/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/StanleyLl0yd/Copiva/actions/workflows/ci.yml)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?logo=apple)](https://github.com/StanleyLl0yd/Copiva/releases/latest)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-F05138?logo=swift&logoColor=white)](Package.swift)

[Русский](README.ru.md) · [Download](https://github.com/StanleyLl0yd/Copiva/releases/latest) · [Roadmap](docs/ROADMAP.md) · [Contribute](CONTRIBUTING.md)

A link, a code snippet, a sentence you wanted to keep — one more copy, and the previous item is gone from the clipboard. Copiva is a native clipboard history project for macOS, built around making those small pieces easy to find and use again.

The idea is simple: open a compact picker, type a few words, choose an item and keep working. Swift, SwiftUI and AppKit provide the foundation; keyboard navigation and a local-first approach guide the design.

## The experience we're building

These capabilities are planned:

- **Recall earlier copies.** Search your history from a compact picker with a configurable global shortcut.
- **Keep useful pieces close.** Pin frequently used items and retain them across restarts and ordinary history cleanup.
- **Choose how to paste.** Reuse supported original formatting or insert plain text.
- **Stay near your work.** Bring up the picker near the insertion point, with safe positioning fallbacks.
- **Keep control of your data.** Local history, configurable retention and privacy controls for sensitive applications, without mandatory cloud services or analytics.

## Try Copiva

[Get the latest release →](https://github.com/StanleyLl0yd/Copiva/releases/latest)

Copiva is in early development. The current release provides the menu-bar app foundation: launch, open the menu and quit. Clipboard history, search and insertion are planned.

macOS 26 or later is required. Development targets Apple Silicon. See the [release notes](https://github.com/StanleyLl0yd/Copiva/releases/latest) for installation, package compatibility and signing details.

## Help shape it

A clipboard tool lives in the small details of everyday work. Useful contributions include:

- Describing a workflow you'd like Copiva to support in an [issue](https://github.com/StanleyLl0yd/Copiva/issues).
- Discussing keyboard interaction, accessibility, privacy or Russian and English wording.
- Contributing Swift code, tests or documentation through a focused pull request.

Start with the [contribution guide](CONTRIBUTING.md) and [roadmap](docs/ROADMAP.md). Please use synthetic examples in reports; clipboard contents can be sensitive.

If you'd like to follow the project, a star makes it easy to find again and helps others discover it.

## Open source

Copiva is available under the [MIT license](LICENSE). You can study it, change it and contribute to its direction.

[Architecture](docs/ARCHITECTURE.md) · [Security policy](SECURITY.md)
