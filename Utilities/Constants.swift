import Foundation

enum Keys {
    static let retentionDays = "tXt.retentionDays"
    static let defaultRetentionDays = 14
    static let minimumRetentionDays = 5
    static let maximumRetentionDays = 30
}

extension Notification.Name {
    static let toggleHUD = Notification.Name("tXt.toggleHUD")
    static let retentionDidChange = Notification.Name("tXt.retentionDidChange")
}
