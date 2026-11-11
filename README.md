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

You copy a link, then a terminal command, then something else. A minute later, you need that first link. It's gone from the clipboard, but one of those 40 open tabs probably has it. Somewhere.

Copiva is the clipboard history app we're building for Mac. The idea is simple: hit a shortcut, type a few words, find what you copied, and paste it. The picker should open right next to where you're typing.

## What we're building

- **Find something you copied earlier.** A link, a quote, a command — even after you've copied a dozen other things.
- **Pin the stuff you keep using.** Save an address or a canned reply. Restarting the app or clearing old history should leave your pinned clips alone.
- **Choose how to paste.** Keep the text's formatting when you want it, or paste plain text when you don't. Your email and your code editor have different needs.
- **Keep your hands on the keyboard.** Pick your own shortcut, search as you type, choose a clip, and paste.

These features are planned. The [roadmap](docs/ROADMAP.md) has more detail.

## Give it a try

**[Download the latest Copiva release](https://github.com/StanleyLl0yd/Copiva/releases/latest)** · [All releases](https://github.com/StanleyLl0yd/Copiva/releases)

Copiva's just getting started. The current release lives in the menu bar: you can launch it, open its menu, and quit. It doesn't save clipboard history yet; search and pasting from history are still to come.

You'll need **macOS 26 or later**. We're focusing future releases on Macs with **Apple Silicon**. Check the release notes for installation and signing details.

## Your clipboard is personal

Shopping lists, work messages, and things you never meant to save all end up on the clipboard. History will stay on your Mac, with settings for how much to keep and which apps to leave out. We also plan to skip items that apps flag as confidential.

You won't need an account or a cloud service to use Copiva. Usage analytics aren't part of the plan either.

## Help build it

[Tell us in an issue](https://github.com/StanleyLl0yd/Copiva/issues) what you wish your clipboard could do. Ideas about search, shortcuts, and how the picker feels are especially useful. Those little details make a difference in an app you might use all day.

If Swift's your thing, take a look at the [contributing guide](CONTRIBUTING.md). The app uses Swift, SwiftUI, and AppKit. Tests, docs, clearer wording, and accessibility feedback are welcome too. Please swap out any personal clipboard content for made-up examples before posting.

And if you like the idea, a **⭐ star** helps other people find Copiva.

Licensed under [MIT](LICENSE).

[Architecture](docs/ARCHITECTURE.md) · [Security](SECURITY.md)
