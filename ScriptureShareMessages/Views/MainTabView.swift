import SwiftUI
import SwiftData

/// Root view for the iMessage extension with tab navigation.
struct MainTabView: View {
    /// Called with the formatted text string to insert into iMessage.
    let onInsertText: (String) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var selectedTab: Int = 0

    private var settings: UserSettings {
        if let existing = settingsResults.first {
            return existing
        }
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BrowseView(onSelectVerse: { verse in handleShare(verse) })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            TranslationBadge()
                        }
                    }
            }
            .tabItem {
                Label("Browse", systemImage: "books.vertical")
            }
            .tag(0)

            NavigationStack {
                DirectEntryView(onSelectVerse: { verse in handleShare(verse) })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            TranslationBadge()
                        }
                    }
            }
            .tabItem {
                Label("Enter", systemImage: "character.cursor.ibeam")
            }
            .tag(1)

            NavigationStack {
                SearchView(onSelectVerse: { verse in handleShare(verse) })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            TranslationBadge()
                        }
                    }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)

            NavigationStack {
                RecentsView(onSelectVerse: { verse in handleShare(verse) })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            TranslationBadge()
                        }
                    }
            }
            .tabItem {
                Label("Recents", systemImage: "clock")
            }
            .tag(3)
        }
        .modelContainer(UserSettings.sharedModelContainer)
    }

    // MARK: - Share Handler

    private func handleShare(_ verse: Verse) {
        // 1. Format the text
        let text = ShareService.shareText(for: verse)

        // 2. Save to recents (use the base verse ID for non-composite verses)
        RecentsService.addRecent(verseID: verse.id, to: settings)

        // 3. Insert into iMessage
        onInsertText(text)
    }
}
