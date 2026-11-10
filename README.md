<h1 align="center">Copiva</h1>

<p align="center">
  <strong>For those “I just copied that” moments.</strong>
</p>

<p align="center">
  <a href="https://github.com/StanleyLl0yd/Copiva/actions/workflows/ci.yml"><img src="https://github.com/StanleyLl0yd/Copiva/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"></a>
  <a href="https://github.com/StanleyLl0yd/Copiva/releases/latest"><img src="https://img.shields.io/github/v/release/StanleyLl0yd/Copiva?label=release" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/StanleyLl0yd/Copiva?label=license" alt="MIT license"></a>
  <a href="https://github.com/StanleyLl0yd/Copiva/releases/latest"><img src="https://img.shields.io/badge/macOS-26%2B-000000?logo=apple" alt="macOS 26+"></a>
  <a href="Package.swift"><img src="https://img.shields.io/badge/Swift-6.2%2B-F05138?logo=swift&amp;logoColor=white" alt="Swift 6.2+"></a>
</p>

<p align="center"><strong>English</strong> · <a href="README.ru.md">Русский</a></p>

Copy a link, then a code snippet, then another link. Now you need the first one. A small archaeological expedition through your browser tabs begins.

Copiva is a native clipboard history project for macOS, built around a simple idea: useful things you've copied should be easy to find and use again. Open a compact picker, type a few words, choose an item and carry on.

We're building it with Swift, SwiftUI and AppKit, with keyboard navigation and local storage at the heart of the design. Your clipboard already has enough to keep track of.

## A little more memory for your clipboard

Here's the experience we're working toward:

- **Find an earlier copy.** Search your history from a compact picker with a configurable global shortcut.
- **Keep the useful bits.** Pin a frequently used snippet and keep it across restarts and ordinary history cleanup.
- **Paste it your way.** Choose supported original formatting or plain text — an email and a code editor don't always want the same thing.
- **Stay near your work.** Bring up the picker near where you're typing.
- **Keep control of your history.** Local storage, configurable retention and privacy controls for applications with sensitive content.

These are planned capabilities. The [roadmap](docs/ROADMAP.md) has the full picture.

## Try Copiva

**[Download the latest release](https://github.com/StanleyLl0yd/Copiva/releases/latest)** · [All releases](https://github.com/StanleyLl0yd/Copiva/releases)

Copiva is in early development. The current release provides the menu-bar app foundation: launch, open the menu and quit. Clipboard history, search and insertion are still ahead.

You'll need **macOS 26 or later**. Development targets **Apple Silicon**; installation, compatibility and signing details for each package live in its release notes.

## Small tool, personal contents

Clipboard history can contain a shopping list, a draft message or something you'd rather keep private. Local processing, clear privacy controls and careful handling of sensitive content are core design requirements. Mandatory cloud services and analytics aren't part of the plan.

## Want to help?

A clipboard tool gets better when people bring their everyday habits to it. [Open an issue](https://github.com/StanleyLl0yd/Copiva/issues) with a workflow you'd like to see, an awkward interaction or a question worth discussing.

Swift code, tests, documentation, accessibility feedback and Russian or English wording are all welcome. Start with the [contribution guide](CONTRIBUTING.md); a focused pull request is a good place to begin. Please use made-up examples instead of personal or confidential clipboard contents.

If you like where Copiva is going, a **⭐ star** helps other people find it — and helps you find it again, too.

Copiva is open source under the [MIT license](LICENSE).

[Architecture](docs/ARCHITECTURE.md) · [Security policy](SECURITY.md)

---

*For the link you knew you'd need again.*
