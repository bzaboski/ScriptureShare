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
                Section {
                    ForEach(Translation.allCases) { translation in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(translation.displayName)
                                        .font(.body.weight(.medium))
                                    if !translation.isLocal && !translation.isAvailable {
                                        Image(systemName: "key")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    if !translation.isLocal {
                                        Image(systemName: "cloud")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(translation.fullName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.preferredTranslation == translation.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if translation.isAvailable {
                                settings.preferredTranslation = translation.rawValue
                                dismiss()
                            }
                        }
                        .opacity(translation.isAvailable ? 1.0 : 0.5)
                    }
                } footer: {
                    if Translation.allCases.contains(where: { !$0.isAvailable }) {
                        Text("Translations marked with a key icon require an API key. Configure keys in APIConfig.swift.")
                            .font(.caption2)
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
