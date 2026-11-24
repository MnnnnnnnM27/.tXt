import AppKit
import SwiftUI

@main
struct tXtApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(".tXt", systemImage: "clipboard") {
            Button("Show Clipboard") {
                NotificationCenter.default.post(name: .toggleHUD, object: nil)
            }
            Divider()
            SettingsLink()
            Divider()
            Button("Quit .tXt") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
