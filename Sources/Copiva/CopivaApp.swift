import AppKit
import CopivaCore
import SwiftUI

@main
struct CopivaApp: App {
    var body: some Scene {
        MenuBarExtra("Copiva", systemImage: "clipboard") {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppInfo.displayName).font(.headline)
                Text("Clipboard manager — in development")
                    .font(.subheadline)
                Divider()
                Button("Quit Copiva") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(16)
        }
        .menuBarExtraStyle(.window)
    }
}
