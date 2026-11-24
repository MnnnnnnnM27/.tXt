import Foundation
import SwiftData

/// Removes unpinned clips outside the user's retention window.
@MainActor
final class CleanupService {
    private let context: ModelContext
    private var timer: Timer?
    private var observer: NSObjectProtocol?

    init(context: ModelContext) {
        self.context = context
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.cleanupNow() }
        }
        RunLoop.main.add(timer!, forMode: .common)

        observer = NotificationCenter.default.addObserver(
            forName: .retentionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.cleanupNow() }
        }
    }

    func cleanupNow() {
        let stored = UserDefaults.standard.integer(forKey: Keys.retentionDays)
        let days = min(
            Keys.maximumRetentionDays,
            max(Keys.minimumRetentionDays, stored == 0 ? Keys.defaultRetentionDays : stored)
        )
        let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)

        let predicate = #Predicate<ClipboardItem> { item in
            !item.isPinned && item.timestamp < cutoff
        }
        let descriptor = FetchDescriptor<ClipboardItem>(predicate: predicate)

        do {
            let stale = try context.fetch(descriptor)
            guard !stale.isEmpty else { return }
            for item in stale {
                context.delete(item)
            }
            try context.save()
        } catch {
            print("[.tXt] Cleanup failed: \(error)")
        }
    }

    deinit {
        timer?.invalidate()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
