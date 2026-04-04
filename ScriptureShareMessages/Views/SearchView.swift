import SwiftUI
import SwiftData

struct SearchView: View {
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var query = ""
    @State private var results: [Verse] = []
    @State private var isSearching = false
    @State private var selectedVerse: Verse?
    @State private var errorMessage: String?

    private let translationService = TranslationService.shared
    private let database = BibleDatabase()

    private var currentTranslation: Translation {
        settingsResults.first.map { Translation.from($0.preferredTranslation) } ?? .kjv
    }

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
                    VStack(spacing: 8) {
                        ProgressView()
                        if !currentTranslation.isLocal {
                            Text("Searching \(currentTranslation.displayName)...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    if error.contains("Offline") {
                        Text("KJV is available offline.")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .listRowSeparator(.hidden)
            } else if results.isEmpty && !query.isEmpty {
                // No results state
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No results for \"\(query)\"")
                        .font(.headline)
                    if currentTranslation == .nlt {
                        Text("NLT only supports reference lookups (e.g. \"John 3:16\"). Try keyword search with KJV or ESV.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Try different keywords or a reference like \"John 3:16\".")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
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
        .searchable(text: $query, prompt: "Search verses or enter a reference...")
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

        let translation = currentTranslation

        if translation.isLocal {
            // Synchronous KJV search
            isSearching = true
            DispatchQueue.global(qos: .userInitiated).async {
                let found = smartSearchLocal(trimmed)
                DispatchQueue.main.async {
                    results = found
                    isSearching = false
                }
            }
        } else {
            // Async API search
            isSearching = true
            Task {
                do {
                    let found = try await smartSearchRemote(trimmed, translation: translation)
                    await MainActor.run {
                        results = found
                        isSearching = false
                    }
                } catch {
                    await MainActor.run {
                        isSearching = false
                        if let tsError = error as? TranslationServiceError, tsError.isOffline {
                            errorMessage = "Offline — switch to KJV for offline access."
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    /// Smart search for local (KJV) translation: tries verse reference parser first, falls back to FTS5.
    private func smartSearchLocal(_ text: String) -> [Verse] {
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

    /// Smart search for remote (ESV/NLT) translations: reference lookup or keyword search.
    private func smartSearchRemote(_ text: String, translation: Translation) async throws -> [Verse] {
        // Try reference parser first
        if let ref = VerseParser.parse(text) {
            if let endVerse = ref.endVerse {
                return try await translationService.verseRange(
                    book: ref.bookName,
                    chapter: ref.chapter,
                    from: ref.verse,
                    through: endVerse,
                    translation: translation
                )
            } else if let verse = try await translationService.verse(
                book: ref.bookName,
                chapter: ref.chapter,
                verse: ref.verse,
                translation: translation
            ) {
                return [verse]
            }
        }

        // Fall back to translation search
        return try await translationService.search(query: text, translation: translation, limit: 50)
    }
}
