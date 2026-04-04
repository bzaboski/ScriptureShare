import SwiftUI
import SwiftData

struct DirectEntryView: View {
    let onSelectVerse: (Verse) -> Void

    @Query private var settingsResults: [UserSettings]
    @Environment(\.modelContext) private var context

    @State private var reference = ""
    @State private var result: Verse?
    @State private var rangeVerses: [Verse] = []
    @State private var errorMessage: String?
    @State private var suggestions: [String] = []
    @State private var isLoading = false

    private let translationService = TranslationService.shared
    private let database = BibleDatabase()

    private var currentTranslation: Translation {
        settingsResults.first.map { Translation.from($0.preferredTranslation) } ?? .kjv
    }

    /// All canonical book names for autocomplete
    private let allBookNames: [String] = {
        VerseParser.bookAliases.map { $0.0 }
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Input Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.pages")
                        .foregroundStyle(.secondary)
                    TextField("e.g. John 3:16 or 1 Cor 13:4-7", text: $reference)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(lookup)
                        .onChange(of: reference) { _, newValue in
                            updateSuggestions(for: newValue)
                        }
                    if !reference.isEmpty {
                        Button {
                            reference = ""
                            result = nil
                            rangeVerses = []
                            errorMessage = nil
                            suggestions = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Look Up button
                Button(action: lookup) {
                    HStack(spacing: 6) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Look Up")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(reference.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .padding(.horizontal)
            }
            .padding(.top, 12)

            // MARK: - Autocomplete Suggestions
            if !suggestions.isEmpty && result == nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(Color.accentColor)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            // MARK: - Error
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // MARK: - Preview Card
            if let verse = result {
                VersePreviewCard(verse: verse, onShare: {
                    onSelectVerse(verse)
                })
                .padding()
            } else if !rangeVerses.isEmpty {
                // Range: composite preview card
                RangePreviewCard(verses: rangeVerses, onShare: {
                    let composite = buildCompositeVerse(rangeVerses)
                    onSelectVerse(composite)
                })
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Direct Entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Autocomplete Logic

    private func updateSuggestions(for input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        // If already a valid reference, no suggestions needed
        if VerseParser.parse(trimmed) != nil {
            suggestions = []
            return
        }

        // Try to detect if a book is already recognized (input has book + partial chapter:verse)
        let bookRecognized = detectRecognizedBook(in: trimmed)

        if let (bookName, rest) = bookRecognized {
            // Book is recognized — suggest chapter:verse hints
            suggestions = buildChapterVerseSuggestions(bookName: bookName, rest: rest)
        } else {
            // Suggest book names that match the prefix
            suggestions = allBookNames
                .filter { $0.lowercased().hasPrefix(trimmed.lowercased()) }
                .prefix(8)
                .map { $0 }
        }
    }

    /// Returns (canonical book name, remainder of input after book) if the input starts with a recognized book.
    private func detectRecognizedBook(in input: String) -> (String, String)? {
        // Try progressively shorter prefixes (longest match first)
        let words = input.split(separator: " ", omittingEmptySubsequences: false).map(String.init)

        // Try combinations of 1, 2, 3 words as book
        for count in stride(from: min(words.count, 3), through: 1, by: -1) {
            let candidate = words.prefix(count).joined(separator: " ")
            if let canonical = VerseParser.resolve(candidate) {
                let remainder = words.dropFirst(count).joined(separator: " ")
                return (canonical, remainder)
            }
        }
        return nil
    }

    private func buildChapterVerseSuggestions(bookName: String, rest: String) -> [String] {
        let chapterCount = translationService.chapterCount(bookName: bookName)
        guard chapterCount > 0 else { return [] }

        // Parse rest to get partial chapter
        let restTrimmed = rest.trimmingCharacters(in: .whitespaces)

        if restTrimmed.isEmpty {
            // Suggest first few chapters
            return (1...min(5, chapterCount)).map { "\(bookName) \($0):" }
        } else if let ch = Int(restTrimmed), !restTrimmed.contains(":") {
            // Have chapter number, suggest adding colon
            return ["\(bookName) \(ch):"]
        } else {
            return []
        }
    }

    private func applySuggestion(_ suggestion: String) {
        reference = suggestion
        // If suggestion ends with ":", put cursor after it (best effort)
        // Trigger lookup if it looks complete
        if VerseParser.parse(suggestion) != nil {
            lookup()
        } else {
            updateSuggestions(for: suggestion)
        }
    }

    // MARK: - Lookup

    private func lookup() {
        let trimmed = reference.trimmingCharacters(in: .whitespaces)
        errorMessage = nil
        result = nil
        rangeVerses = []

        guard let ref = VerseParser.parse(trimmed) else {
            if trimmed.isEmpty {
                errorMessage = "Please enter a reference like \"John 3:16\"."
            } else {
                errorMessage = "Couldn't parse \"\(trimmed)\". Try \"John 3:16\" or \"1 Cor 13:4-7\"."
            }
            return
        }

        suggestions = []

        let translation = currentTranslation

        if translation.isLocal {
            // Synchronous KJV lookup
            performLocalLookup(ref: ref)
        } else {
            // Async API lookup
            performRemoteLookup(ref: ref, translation: translation)
        }
    }

    /// KJV: synchronous database lookup.
    private func performLocalLookup(ref: VerseReference) {
        if let endVerse = ref.endVerse {
            let verses = database.verses(bookName: ref.bookName, chapter: ref.chapter, from: ref.verse, through: endVerse)
            if verses.isEmpty {
                errorMessage = "Verse range not found: \(ref.displayString)."
            } else {
                rangeVerses = verses
            }
        } else {
            if let verse = database.verse(bookName: ref.bookName, chapter: ref.chapter, verse: ref.verse) {
                result = verse
            } else {
                errorMessage = "Verse not found: \(ref.displayString)."
            }
        }
    }

    /// ESV/NLT: async API lookup with loading state.
    private func performRemoteLookup(ref: VerseReference, translation: Translation) {
        isLoading = true
        Task {
            do {
                if let endVerse = ref.endVerse {
                    let verses = try await translationService.verseRange(
                        book: ref.bookName,
                        chapter: ref.chapter,
                        from: ref.verse,
                        through: endVerse,
                        translation: translation
                    )
                    await MainActor.run {
                        isLoading = false
                        if verses.isEmpty {
                            errorMessage = "Verse range not found: \(ref.displayString)."
                        } else {
                            rangeVerses = verses
                        }
                    }
                } else {
                    let verse = try await translationService.verse(
                        book: ref.bookName,
                        chapter: ref.chapter,
                        verse: ref.verse,
                        translation: translation
                    )
                    await MainActor.run {
                        isLoading = false
                        if let verse = verse {
                            result = verse
                        } else {
                            errorMessage = "Verse not found: \(ref.displayString)."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let tsError = error as? TranslationServiceError, tsError.isOffline {
                        errorMessage = "Offline — switch to KJV for offline access."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    // MARK: - Composite Verse for Ranges

    private func buildCompositeVerse(_ verses: [Verse]) -> Verse {
        guard let first = verses.first, let last = verses.last else {
            return Verse(id: 0, bookName: "", chapterNumber: 0, verseNumber: 0, text: "")
        }
        let text = VerseParser.formatRange(verses)
        return Verse(
            id: first.id,
            bookName: first.bookName,
            chapterNumber: first.chapterNumber,
            verseNumber: first.verseNumber,
            endVerseNumber: last.verseNumber,
            text: text,
            translation: first.translation
        )
    }
}

// MARK: - Range Preview Card

struct RangePreviewCard: View {
    let verses: [Verse]
    let onShare: () -> Void

    private var first: Verse? { verses.first }
    private var last: Verse? { verses.last }

    private var referenceString: String {
        guard let f = first, let l = last else { return "" }
        return "\(f.bookName) \(f.chapterNumber):\(f.verseNumber)-\(l.verseNumber)"
    }

    private var formattedText: String {
        VerseParser.formatRange(verses)
    }

    private var attributionText: String {
        guard let f = first else { return "(KJV)" }
        return CopyrightService.sharingAttribution(for: Translation.from(f.translation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedText)
                .font(.body)
                .italic()

            HStack {
                Text("— \(referenceString) \(attributionText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onShare) {
                    Label("Share", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}
