# .tXt

A lightweight, native macOS clipboard manager. It runs as a background utility
(no Dock icon), captures text and image clips, and lets you paste any earlier
clip back into the app you were using with `Option+V` → navigate → `Return`.

Deployment target: **macOS 14+** (SwiftData).

## File structure

```
.tXt/
├── .tXtApp.swift                      # @main App, MenuBarExtra, Settings scene
├── AppDelegate.swift                  # background setup, wires up services
├── Info.plist                         # LSUIElement = true, display name ".tXt"
├── Models/
│   └── ClipboardItem.swift            # SwiftData @Model: text / image / date / pinned
├── Controllers/
│   └── HUDWindowController.swift      # centered floating NSPanel lifecycle
├── Services/
│   ├── HotKeyMonitor.swift            # CGEventTap for global Option+V
│   ├── ClipboardMonitor.swift         # pasteboard polling + persistence
│   ├── CleanupService.swift           # retention-window pruning
│   └── PasteSimulator.swift           # write to pasteboard + synthetic Cmd+V
├── Views/
│   ├── HUDView.swift                  # search, list, arrow keys, Enter, Escape
│   ├── ClipboardRowView.swift         # row rendering + pin/delete context menu
│   └── SettingsView.swift             # 5–30 day retention picker
└── Utilities/
    ├── Constants.swift                # UserDefaults keys + notifications
    └── Persistence.swift              # shared ModelContainer
```

## Xcode setup

1. Create a new **macOS App** project (SwiftUI lifecycle) named `.tXt` with
   **macOS 14.0** or later as the deployment target.
2. Add all the Swift files above to the app target.
3. Point the target's **Info.plist** at the included `Info.plist`, or add these
   keys to the generated one:
   - `Application is agent (UIElement)` = `YES` (`LSUIElement = true`)
   - `CFBundleDisplayName` = `.tXt`
4. Embed no storyboard; the `MenuBarExtra` is the only UI entry point.

## Permissions

The global `Option+V` tap uses `CGEvent.tapCreate`. On first launch macOS will
ask for **Accessibility** access (System Settings → Privacy & Security →
Accessibility). The app retries tap installation while permission is pending.

## Behaviour notes

- `Option+V` toggles the HUD; the event is consumed so it does not type a
  character into the frontmost app.
- The panel is a nonactivating floating panel, so the previously focused app
  stays active. On `Return` the HUD closes focus is restored, then a tagged
  synthetic `Cmd+V` is posted. The tag prevents the global tap and clipboard
  monitor from reacting to that synthetic event.
- Images are normalised to PNG when captured and written back as `public.png`.
- Cleanup runs at launch, on retention changes, and hourly. Pinned items are
  never deleted.
- Right-click a row to pin or delete it.
