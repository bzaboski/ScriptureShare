import SwiftUI

struct SearchView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var query = ""
    @State private var results: [Verse] = []
    @State private var isSearching = false
    @State private var selectedVerse: Verse?
    @State private var errorMessage: String?

    private let database = BibleDatabase()

    var body: some View {
        Group {
            if let verse = selectedVerse {
                // Verse preview card for quick share
                VStack {
                    VersePreviewCard(verse: verse, onShare: {
                        onSelectVerse(verse)
                        selectedVerse = nil
                    })
                    .padding()
                    Spacer()
                }
                .navigationTitle(verse.reference)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { selectedVerse = nil }
                    }
                }
            } else {
                searchResultsView
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        List {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .listRowSeparator(.hidden)
            } else if results.isEmpty && !query.isEmpty {
                // No results state
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No results for \"\(query)\"")
                        .font(.headline)
                    Text("Try different keywords or a reference like \"John 3:16\".")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
            } else {
                ForEach(results) { verse in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.reference)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(verse.text)
                            .font(.body)
                            .lineLimit(3)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedVerse = verse }
                    .listRowSeparator(.visible)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "Search verses or enter a reference…")
        .onChange(of: query) { _, newValue in
            performSearch(newValue)
        }
    }

    // MARK: - Smart Search

    private func performSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        errorMessage = nil
        selectedVerse = nil

        guard trimmed.count >= 2 else {
            results = []
            return
        }

        isSearching = true

        DispatchQueue.global(qos: .userInitiated).async {
            let found = smartSearch(trimmed)
            DispatchQueue.main.async {
                results = found
                isSearching = false
            }
        }
    }

    /// Smart search: tries verse reference parser first, falls back to FTS5.
    private func smartSearch(_ text: String) -> [Verse] {
        // Try reference parser first
        if let ref = VerseParser.parse(text) {
            if let endVerse = ref.endVerse {
                return database.verses(bookName: ref.bookName, chapter: ref.chapter,
                                       from: ref.verse, through: endVerse)
            } else if let verse = database.verse(bookName: ref.bookName, chapter: ref.chapter, verse: ref.verse) {
                return [verse]
            }
        }

        // Fall back to FTS5 keyword search (capped at 50)
        return database.search(query: text, limit: 50)
    }
}
