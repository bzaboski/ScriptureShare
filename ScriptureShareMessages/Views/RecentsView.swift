import SwiftUI

struct RecentsView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var recentVerses: [Verse] = []

    private let database = BibleDatabase()

    var body: some View {
        Group {
            if recentVerses.isEmpty {
                ContentUnavailableView(
                    "No Recent Verses",
                    systemImage: "clock",
                    description: Text("Verses you share will appear here.")
                )
            } else {
                List(recentVerses) { verse in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.text)
                            .font(.body)
                            .lineLimit(2)
                        Text(verse.reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectVerse(verse) }
                }
            }
        }
        .navigationTitle("Recents")
    }

    func load(verseIDs: [Int]) {
        recentVerses = verseIDs.compactMap { database.verse(id: $0) }
    }
}
