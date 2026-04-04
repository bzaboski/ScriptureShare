import SwiftUI

struct VersePreviewCard: View {
    let verse: Verse
    let onShare: () -> Void

    private var attributionText: String {
        CopyrightService.sharingAttribution(for: Translation.from(verse.translation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verse.text)
                .font(.body)
                .italic()

            HStack {
                Text("— \(verse.reference) \(attributionText)")
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
