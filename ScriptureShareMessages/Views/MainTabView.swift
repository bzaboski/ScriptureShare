import SwiftUI

/// Root view for the iMessage extension with tab navigation.
struct MainTabView: View {
    let onInsertVerse: (Verse) -> Void

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BrowseView(onSelectVerse: onInsertVerse)
            }
            .tabItem {
                Label("Browse", systemImage: "books.vertical")
            }
            .tag(0)

            NavigationStack {
                DirectEntryView(onSelectVerse: onInsertVerse)
            }
            .tabItem {
                Label("Enter", systemImage: "character.cursor.ibeam")
            }
            .tag(1)

            NavigationStack {
                SearchView(onSelectVerse: onInsertVerse)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)

            NavigationStack {
                RecentsView(onSelectVerse: onInsertVerse)
            }
            .tabItem {
                Label("Recents", systemImage: "clock")
            }
            .tag(3)
        }
    }
}
