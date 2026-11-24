import AppKit
import SwiftData
import SwiftUI

/// A nonactivating panel that can still own keyboard focus for the search field.
final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the single floating HUD panel.
@MainActor
final class HUDWindowController: ObservableObject {
    static let shared = HUDWindowController()

    private var panel: NSPanel?
    private var previousApp: NSRunningApplication?
    private var observer: NSObjectProtocol?
    private let container = Persistence.container

    private init() {}

    func install() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .toggleHUD,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.toggle() }
        }
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        previousApp = NSWorkspace.shared.frontmostApplication

        let root = HUDView { [weak self] in self?.hide() }
            .modelContainer(container)

        let panel = HUDPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.contentViewController = NSHostingController(rootView: root)
        panel.setContentSize(NSSize(width: 440, height: 380))

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(
                NSPoint(
                    x: frame.midX - panel.frame.width / 2,
                    y: frame.midY - panel.frame.height / 2
                )
            )
        }

        panel.orderFrontRegardless()
        panel.makeKey()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        // Return focus to wherever the user was before the HUD appeared, so a
        // synthetic Cmd+V lands in the right app.
        previousApp?.activate()
        previousApp = nil
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
