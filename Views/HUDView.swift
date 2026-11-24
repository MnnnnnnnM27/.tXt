import SwiftData
import SwiftUI

struct HUDView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var items: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedIndex: Int?
    @FocusState private var isSearchFocused: Bool

    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    private var filtered: [ClipboardItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter { item in
            if let text = item.text, text.localizedCaseInsensitiveContains(query) {
                return true
            }
            return item.isImage && "image picture screenshot".localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clipboard")
                    .foregroundStyle(.secondary)

                TextField("Search clipboard…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .focused($isSearchFocused)
                    .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
                    .onKeyPress(.downArrow) { moveSelection(1); return .handled }
                    .onKeyPress(.return) { commit(); return .handled }
                    .onKeyPress(.escape) { onDismiss(); return .handled }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(
                            Array(filtered.enumerated()),
                            id: \.element.persistentModelID
                        ) { index, item in
                            ClipboardRowView(item: item, isSelected: index == selectedIndex)
                                .id(item.persistentModelID)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedIndex = index
                                    commit(at: index)
                                }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .onChange(of: selectedIndex) { _, index in
                    guard let index, index < filtered.count else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(filtered[index].persistentModelID, anchor: .center)
                    }
                }
            }

            HStack {
                Text("↑↓ navigate   ⏎ paste   esc close")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            isSearchFocused = true
            selectedIndex = filtered.isEmpty ? nil : 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = filtered.isEmpty ? nil : 0
        }
    }

    private func moveSelection(_ delta: Int) {
        guard !filtered.isEmpty else { return }
        let current = selectedIndex ?? 0
        selectedIndex = min(max(current + delta, 0), filtered.count - 1)
    }

    private func commit(at index: Int? = nil) {
        let resolved = index ?? selectedIndex ?? 0
        guard filtered.indices.contains(resolved) else { return }
        let item = filtered[resolved]

        PasteSimulator.write(item)
        ClipboardMonitor.ignoreCurrentChange()

        onDismiss()

        // Give the previous app a moment to become key again before pasting.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            PasteSimulator.postPaste()
        }
    }
}
