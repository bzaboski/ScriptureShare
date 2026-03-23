import SwiftUI

struct SearchView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var query = ""
    @State private var results: [Verse] = []
    @State private var isSearching = false

    private let database = BibleDatabase()

    var body: some View {
        NavigationStack {
            List(results) { verse in
                VStack(alignment: .leading, spacing: 4) {
                    Text(verse.text)
                        .font(.body)
                        .lineLimit(3)
                    Text(verse.reference)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelectVerse(verse) }
            }
            .overlay {
                if results.isEmpty && !query.isEmpty && !isSearching {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: "Search verses…")
            .onChange(of: query) { _, newValue in
                performSearch(newValue)
            }
            .navigationTitle("Scripture Share")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func performSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            return
        }
        isSearching = true
        DispatchQueue.global(qos: .userInitiated).async {
            let found = database.search(query: trimmed)
            DispatchQueue.main.async {
                results = found
                isSearching = false
            }
        }
    }
}
