import SwiftUI
import SwiftData

/// Picker sheet for selecting a Bible translation.
/// Designed to be presented as a sheet from any view.
public struct TranslationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    private var settings: UserSettings {
        if let existing = settingsResults.first {
            return existing
        }
        let newSettings = UserSettings()
        context.insert(newSettings)
        return newSettings
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(UserSettings.availableTranslations, id: \.self) { translation in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(translation)
                                .font(.body.weight(.medium))
                            Text(subtitleForTranslation(translation))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if settings.preferredTranslation == translation {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.preferredTranslation = translation
                        dismiss()
                    }
                }
            }
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func subtitleForTranslation(_ translation: String) -> String {
        switch translation {
        case "KJV": return "King James Version (1611)"
        case "ESV": return "English Standard Version"
        case "NLT": return "New Living Translation"
        default:    return translation
        }
    }
}

/// A small badge button that shows the current translation abbreviation.
/// Tap to open the translation picker sheet.
public struct TranslationBadge: View {
    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context
    @State private var showPicker = false

    private var translation: String {
        settingsResults.first?.preferredTranslation ?? "KJV"
    }

    public init() {}

    public var body: some View {
        Button {
            showPicker = true
        } label: {
            Text(translation)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
        .sheet(isPresented: $showPicker) {
            TranslationPickerView()
        }
    }
}
