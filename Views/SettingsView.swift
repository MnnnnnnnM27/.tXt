import SwiftUI

struct SettingsView: View {
    @AppStorage(Keys.retentionDays) private var retentionDays = Keys.defaultRetentionDays

    var body: some View {
        Form {
            Section("History") {
                Picker("Keep for", selection: $retentionDays) {
                    ForEach(Keys.minimumRetentionDays...Keys.maximumRetentionDays, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
                Text("Unpinned clips older than \(retentionDays) days are deleted automatically. Pinned clips are kept forever.")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundStyle(.secondary)
            }

            Section("Shortcut") {
                Label("Option + V — toggle clipboard HUD", systemImage: "command")
            }
        }
        .frame(width: 360)
        .padding()
        .onChange(of: retentionDays) { _, _ in
            NotificationCenter.default.post(name: .retentionDidChange, object: nil)
        }
    }
}
