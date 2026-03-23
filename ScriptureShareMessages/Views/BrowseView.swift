import SwiftUI

struct BrowseView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var books: [Book] = []
    @State private var selectedBook: Book?

    private let database = BibleDatabase()

    var body: some View {
        List(books) { book in
            NavigationLink(book.name) {
                ChapterListView(book: book, database: database, onSelectVerse: onSelectVerse)
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

private struct ChapterListView: View {
    let book: Book
    let database: BibleDatabase
    let onSelectVerse: (Verse) -> Void

    @State private var chapterCount = 0

    var body: some View {
        List(1...max(1, chapterCount), id: \.self) { ch in
            NavigationLink("Chapter \(ch)") {
                VerseListView(book: book, chapter: ch, database: database, onSelectVerse: onSelectVerse)
            }
        }
        .navigationTitle(book.name)
        .onAppear {
            if chapterCount == 0 {
                chapterCount = database.chapterCount(bookName: book.name)
            }
        }
    }
}

private struct VerseListView: View {
    let book: Book
    let chapter: Int
    let database: BibleDatabase
    let onSelectVerse: (Verse) -> Void

    @State private var verses: [Verse] = []

    var body: some View {
        List(verses) { verse in
            VStack(alignment: .leading, spacing: 4) {
                Text(verse.text)
                    .font(.body)
                Text("\(book.name) \(chapter):\(verse.verseNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelectVerse(verse) }
        }
        .navigationTitle("\(book.name) \(chapter)")
        .onAppear {
            if verses.isEmpty {
                verses = database.verses(bookName: book.name, chapter: chapter)
            }
        }
    }
}
