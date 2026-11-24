import AppKit
import CoreGraphics

enum PasteSimulator {
    /// Tag applied to synthetic events so the global event tap ignores them.
    static let userDataTag: Int64 = 91_337

    private static let vKeyCode: CGKeyCode = 9 // kVK_ANSI_V
    private static let pngType = NSPasteboard.PasteboardType(rawValue: "public.png")

    /// Put the selected clip back on the system pasteboard.
    static func write(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let data = item.imageData {
            pasteboard.setData(data, forType: pngType)
        } else if let text = item.text {
            pasteboard.setString(text, forType: .string)
        }
    }

    /// Post a Command+V keystroke into the currently focused application.
    static func postPaste() {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false)
        else { return }

        down.flags = [.maskCommand]
        up.flags = [.maskCommand]
        down.setIntegerValueField(.eventSourceUserData, value: userDataTag)
        up.setIntegerValueField(.eventSourceUserData, value: userDataTag)

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
