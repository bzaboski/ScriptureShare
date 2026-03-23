import SwiftUI
import SwiftData

struct RecentsView: View {
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var recentVerses: [Verse] = []
    @State private var selectedVerse: Verse?

    private let database = BibleDatabase()

    private var settings: UserSettings {
        if let existing = settingsResults.first {
            return existing
        }
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }

    var body: some View {
        Group {
            if let verse = selectedVerse {
                // Preview card for quick re-share
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
            } else if recentVerses.isEmpty {
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
                    .onTapGesture { selectedVerse = verse }
                }
            }
        }
        .navigationTitle("Recents")
        .onChange(of: settings.recentVerseIDs) { _, ids in
            loadVerses(ids: ids)
        }
        .onAppear {
            loadVerses(ids: settings.recentVerseIDs)
        }
    }

    private func loadVerses(ids: [Int]) {
        recentVerses = ids.compactMap { database.verse(id: $0) }
    }
}
