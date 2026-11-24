import SwiftData

enum Persistence {
    static let container: ModelContainer = {
        let schema = Schema([ClipboardItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create .tXt store: \(error)")
        }
    }()
}
