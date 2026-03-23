import SwiftUI

/// Top-level Browse view: OT/NT grouped book list.
struct BrowseView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var books: [Book] = []

    private let database = BibleDatabase()

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
                                database: database,
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
                                database: database,
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
                books = database.allBooks()
            }
        }
    }
}

// MARK: - Chapter Grid View

struct ChapterGridView: View {
    let book: Book
    let database: BibleDatabase
    let onSelectVerse: (Verse) -> Void

    @State private var chapterCount: Int = 0

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
                            database: database,
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
                chapterCount = database.chapterCount(bookName: book.name)
            }
        }
    }
}

// MARK: - Verse List View

struct VerseListView: View {
    let book: Book
    let chapter: Int
    let database: BibleDatabase
    let onSelectVerse: (Verse) -> Void

    @State private var verses: [Verse] = []
    @State private var selectedVerse: Verse?

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
                verses = database.verses(bookName: book.name, chapter: chapter)
            }
        }
    }
}
