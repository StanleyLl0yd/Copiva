import AppKit
import CopivaMac
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let onRecord: (GlobalShortcut) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onRecord = onRecord
        view.onCancel = onCancel
        view.setAccessibilityLabel("Press a shortcut using Command, Control or Option. Escape cancels.")
        return view
    }

    func updateNSView(_ view: RecorderView, context: Context) {
        view.onRecord = onRecord
        view.onCancel = onCancel
    }

    final class RecorderView: NSView {
        var onRecord: ((GlobalShortcut) -> Void)?
        var onCancel: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 { onCancel?(); return }
            let shortcut = GlobalShortcut.from(event)
            if shortcut.isValid { onRecord?(shortcut) }
            else { NSSound.beep() }
        }
    }
}
