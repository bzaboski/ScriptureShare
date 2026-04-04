import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var showTranslationPicker = false
    @State private var showClearConfirm = false

    private var settings: UserSettings {
        if let existing = settingsResults.first {
            return existing
        }
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            // MARK: - Translation
            Section("Translation") {
                Button {
                    showTranslationPicker = true
                } label: {
                    HStack {
                        Text("Current Translation")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(settings.preferredTranslation)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .sheet(isPresented: $showTranslationPicker) {
                    TranslationPickerView()
                        .modelContainer(UserSettings.sharedModelContainer)
                }
            }

            // MARK: - Recents
            Section("Recents") {
                HStack {
                    Text("Saved Verses")
                    Spacer()
                    Text("\(settings.recentVerseIDs.count)")
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("Clear Recents", systemImage: "trash")
                }
                .confirmationDialog(
                    "Clear all recent verses?",
                    isPresented: $showClearConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Clear Recents", role: .destructive) {
                        RecentsService.clearRecents(in: settings)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            // MARK: - Copyright Notices
            Section("Copyright Notices") {
                ForEach(CopyrightService.allAttributions(), id: \.translation) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.translation.fullName)
                            .font(.subheadline.weight(.medium))
                        Text(item.text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            // MARK: - About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Bill Zaboski / Z-Team Apps")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Scripture Share")
                        .font(.body.weight(.medium))
                    Text("Search and share Bible verses directly in iMessage conversations. KJV is fully offline. ESV and NLT require an internet connection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(UserSettings.sharedModelContainer)
}
