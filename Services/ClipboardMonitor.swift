import AppKit
import SwiftData

/// Polls the general pasteboard and persists every new text or image clip.
@MainActor
final class ClipboardMonitor {
    private static var ignoredChangeCount: Int?
    private static let pngType = NSPasteboard.PasteboardType(rawValue: "public.png")

    private let context: ModelContext
    private var timer: Timer?
    private var lastChangeCount: Int

    init(context: ModelContext) {
        self.context = context
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    /// Call right after `.tXt` writes to the pasteboard so the restore itself
    /// does not show up as a new history entry.
    static func ignoreCurrentChange() {
        ignoredChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count

        if Self.ignoredChangeCount == count {
            Self.ignoredChangeCount = nil
            return
        }

        capture(from: pasteboard)
    }

    private func capture(from pasteboard: NSPasteboard) {
        // Prefer image payloads: many apps put both an image and a URL on the
        // pasteboard when you copy a picture.
        if let png = pngData(from: pasteboard) {
            insert(imageData: png)
            return
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        insert(text: text)
    }

    private func pngData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: Self.pngType) { return png }
        guard let tiff = pasteboard.data(forType: .tiff),
              let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    private func insert(text: String? = nil, imageData: Data? = nil) {
        if let text, isRecentDuplicate(text) { return }

        context.insert(ClipboardItem(text: text, imageData: imageData))
        do {
            try context.save()
        } catch {
            print("[.tXt] Failed to save clip: \(error)")
        }
    }

    private func isRecentDuplicate(_ text: String) -> Bool {
        let cutoff = Date().addingTimeInterval(-60)
        var descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate<ClipboardItem> { item in
                item.timestamp > cutoff && item.text == text && item.imageData == nil
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor).first) != nil
    }

    deinit {
        timer?.invalidate()
    }
}
