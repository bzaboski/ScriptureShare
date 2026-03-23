import SwiftUI

struct DirectEntryView: View {
    let onSelectVerse: (Verse) -> Void

    @State private var reference = ""
    @State private var result: Verse?
    @State private var errorMessage: String?

    private let database = BibleDatabase()

    var body: some View {
        VStack(spacing: 16) {
            TextField("e.g. John 3:16", text: $reference)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .onSubmit(lookup)

            Button("Look Up", action: lookup)
                .buttonStyle(.borderedProminent)
                .disabled(reference.trimmingCharacters(in: .whitespaces).isEmpty)

            if let verse = result {
                VersePreviewCard(verse: verse, onShare: { onSelectVerse(verse) })
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Direct Entry")
    }

    private func lookup() {
        guard let ref = VerseParser.parse(reference) else {
            errorMessage = "Couldn't parse \"\(reference)\". Try \"John 3:16\"."
            result = nil
            return
        }
        result = database.verse(bookName: ref.bookName, chapter: ref.chapter, verse: ref.verse)
        errorMessage = result == nil ? "Verse not found." : nil
    }
}
