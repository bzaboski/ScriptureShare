import SwiftUI
import SwiftData

/// Top-level Browse view: OT/NT grouped book list.
struct BrowseView: View {
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var books: [Book] = []

    private let translationService = TranslationService.shared

    private var currentTranslation: Translation {
        settingsResults.first.map { Translation.from($0.preferredTranslation) } ?? .kjv
    }

    private var oldTestamentBooks: [Book] { books.filter { $0.testament == "OT" } }
    private var newTestamentBooks: [Book] { books.filter { $0.testament == "NT" } }

    var body: some View {
        List {
            if !oldTestamentBooks.isEmpty {
                Section(header: Text("Old Testament").fontWeight(.semibold)) {
                    ForEach(oldTestamentBooks) { book in
                        NavigationLink {
                            ChapterGridView(
                                book: book,
                                onSelectVerse: onSelectVerse
                            )
                        } label: {
                            Text(book.name)
                        }
                    }
                }
            }

            if !newTestamentBooks.isEmpty {
                Section(header: Text("New Testament").fontWeight(.semibold)) {
                    ForEach(newTestamentBooks) { book in
                        NavigationLink {
                            ChapterGridView(
                                book: book,
                                onSelectVerse: onSelectVerse
                            )
                        } label: {
                            Text(book.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Books")
        .onAppear {
            if books.isEmpty {
                books = translationService.allBooks(translation: currentTranslation)
            }
        }
    }
}

// MARK: - Chapter Grid View

struct ChapterGridView: View {
    let book: Book
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var chapterCount: Int = 0

    private let translationService = TranslationService.shared

    private var currentTranslation: Translation {
        settingsResults.first.map { Translation.from($0.preferredTranslation) } ?? .kjv
    }

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...max(1, chapterCount), id: \.self) { chapter in
                    NavigationLink {
                        VerseListView(
                            book: book,
                            chapter: chapter,
                            onSelectVerse: onSelectVerse
                        )
                    } label: {
                        Text("\(chapter)")
                            .font(.body.weight(.medium))
                            .frame(minWidth: 44, minHeight: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if chapterCount == 0 {
                chapterCount = translationService.chapterCount(bookName: book.name)
            }
        }
    }
}

// MARK: - Verse List View

struct VerseListView: View {
    let book: Book
    let chapter: Int
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var verses: [Verse] = []
    @State private var selectedVerse: Verse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let translationService = TranslationService.shared

    private var currentTranslation: Translation {
        settingsResults.first.map { Translation.from($0.preferredTranslation) } ?? .kjv
    }

    var body: some View {
        Group {
            if let verse = selectedVerse {
                // Show preview card with back button
                VStack {
                    VersePreviewCard(verse: verse, onShare: { onSelectVerse(verse) })
                        .padding()
                    Spacer()
                }
                .navigationTitle("\(book.name) \(chapter):\(verse.verseNumber)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { selectedVerse = nil }
                    }
                }
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading \(currentTranslation.displayName)...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("\(book.name) \(chapter)")
                .navigationBarTitleDisplayMode(.inline)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { loadVerses() }
                        .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("\(book.name) \(chapter)")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                List(verses) { verse in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.text)
                            .font(.body)
                            .lineLimit(3)
                        Text("\(book.name) \(chapter):\(verse.verseNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVerse = verse
                    }
                }
                .navigationTitle("\(book.name) \(chapter)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            if verses.isEmpty {
                loadVerses()
            }
        }
        .onChange(of: settingsResults.first?.preferredTranslation) { _, _ in
            loadVerses()
        }
    }

    private func loadVerses() {
        let translation = currentTranslation

        if translation.isLocal {
            // Synchronous KJV lookup — no loading state needed
            let db = BibleDatabase()
            verses = db.verses(bookName: book.name, chapter: chapter)
            errorMessage = verses.isEmpty ? "No verses found." : nil
        } else {
            // Async API lookup — show loading spinner
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    let result = try await translationService.verses(
                        book: book.name,
                        chapter: chapter,
                        translation: translation
                    )
                    await MainActor.run {
                        verses = result
                        isLoading = false
                        errorMessage = result.isEmpty ? "No verses found." : nil
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
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
}
