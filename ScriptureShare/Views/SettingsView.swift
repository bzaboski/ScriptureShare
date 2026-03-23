import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsResults: [UserSettings]

    private var settings: UserSettings? { settingsResults.first }

    var body: some View {
        NavigationStack {
            List {
                Section("Translation") {
                    Text(settings?.preferredTranslation ?? "KJV")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(UserSettings.sharedModelContainer)
}
