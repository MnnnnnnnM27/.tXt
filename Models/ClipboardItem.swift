import Foundation
import SwiftData

@Model
final class ClipboardItem {
    /// Plain-text payload (nil for image-only clips).
    var text: String?
    /// PNG-encoded payload (nil for text clips).
    var imageData: Data?
    var timestamp: Date
    var isPinned: Bool

    init(
        text: String? = nil,
        imageData: Data? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false
    ) {
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.isPinned = isPinned
    }

    var isImage: Bool { imageData != nil }
}
