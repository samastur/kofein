import AppKit
import KofeinCore
import SwiftUI

/// Window hosting the SwiftUI profile manager. One instance is reused.
@MainActor
final class ProfilesWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    init(store: ProfileStore) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.string("profiles.window.title")
        window.contentView = NSHostingView(rootView: ProfilesView(store: store))
        window.isReleasedWhenClosed = false
        window.center()
        super.init()
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
