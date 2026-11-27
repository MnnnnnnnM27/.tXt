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

# Installation:
There are two ways to install tXt

## 1. Xcode setup
1. Download all the files as a zip (Using the green '<> Code' button)
2. Unzip the files
3. Create a Xcode project, name it 'tXt', and delete all the files already in the project
4. Create a new target and name it 'tXt'
5. Remove any old targets
6. To that target, add all the files from the .zip
7. Click 'Product' in the menu bar, then click 'Archive'
8. Click 'Distribute App', then choose 'Custom'
9. Select 'Copy App' and copy it to Applications under the name 'tXt' (not .tXt, because macOS hides files that begin with '.')

## 2. Simple Download
1. Go to the **LATEST** release page, and download the .zip file from there
2. Unzip it to find the .app file
3. Move the .app file to your Applications folder

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
