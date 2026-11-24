import AppKit
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyMonitor: HotKeyMonitor?
    private var clipboardMonitor: ClipboardMonitor?
    private var cleanupService: CleanupService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-braces: Info.plist sets LSUIElement, this guarantees
        // background-utility behaviour even if the plist is not wired up.
        NSApp.setActivationPolicy(.accessory)

        UserDefaults.standard.register(
            defaults: [Keys.retentionDays: Keys.defaultRetentionDays]
        )

        let container = Persistence.container
        let context = container.mainContext

        HUDWindowController.shared.install()

        clipboardMonitor = ClipboardMonitor(context: context)
        clipboardMonitor?.start()

        cleanupService = CleanupService(context: context)
        cleanupService?.start()
        cleanupService?.cleanupNow()

        hotKeyMonitor = HotKeyMonitor {
            Task { @MainActor in HUDWindowController.shared.toggle() }
        }
        hotKeyMonitor?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
