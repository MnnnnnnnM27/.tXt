import AppKit
import SwiftData
import SwiftUI

struct ClipboardRowView: View {
    @Environment(\.modelContext) private var modelContext

    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            if item.isImage, let data = item.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 46, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text("Image")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .lineLimit(1)
            } else if let text = item.text {
                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
            }

            Text(item.timestamp, style: .relative)
                .font(.system(size: 11, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.28) : Color.clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin") {
                item.isPinned.toggle()
                try? modelContext.save()
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            }
        }
    }
}
