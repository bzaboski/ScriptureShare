import SwiftUI

// MARK: - App Store Screenshot Frames
//
// Run each preview on an iPhone 15 Pro Max simulator (6.7").
// Use Device > Screenshot (⌘S) or File > Export Screenshot to save.
// Required size: 1290 × 2796 px  (the simulator renders at 3× — 430 × 932 pts)
//
// Five screenshots:
//  1. Search in action          — hero shot
//  2. Browse the full Bible     — book list
//  3. Share a verse             — verse preview card
//  4. Type any reference        — direct entry
//  5. Recently shared           — recents
//
// Each frame: gradient background + marketing headline + Messages chrome mockup.

// MARK: - Shared Frame

private struct ScreenshotFrame<Content: View>: View {
    let headline: String
    let subhead: String
    let gradientStart: Color
    let gradientEnd: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [gradientStart, gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Marketing copy
                VStack(spacing: 8) {
                    Text(headline)
                        .font(.system(.largeTitle, design: .default, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(subhead)
                        .font(.system(.subheadline, design: .default))
                        .foregroundStyle(.white.opacity(0.80))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 28)

                // Messages chrome mockup
                MessagesChrome {
                    content()
                }
                .padding(.horizontal, 12)

                Spacer()

                // App branding footer
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                    Text("Scripture Share")
                        .font(.system(.footnote, design: .default, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Messages Chrome Mockup

/// Simulates the Messages app conversation + extension panel chrome.
private struct MessagesChrome<Extension: View>: View {
    @ViewBuilder let extensionContent: () -> Extension

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.blue)
                Spacer()
                VStack(spacing: 1) {
                    Circle()
                        .fill(Color(red: 0.75, green: 0.85, blue: 1.0))
                        .frame(width: 32, height: 32)
                        .overlay(Text("JD").font(.system(size: 12, weight: .semibold)).foregroundStyle(.blue))
                    Text("John Doe")
                        .font(.system(size: 12, weight: .semibold))
                }
                Spacer()
                Image(systemName: "video.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)

            Divider()

            // Conversation bubbles
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    ChatBubble(text: "Have a great day! Here's something for you 🙏", isMe: false)
                    Spacer()
                }
                HStack {
                    Spacer()
                    ChatBubble(text: "\"For God so loved the world, that he gave his only begotten Son\" — John 3:16 (KJV)", isMe: true)
                }
                HStack {
                    ChatBubble(text: "Thank you! That's perfect 💙", isMe: false)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))

            // Compose + app bar
            HStack(spacing: 8) {
                HStack {
                    Text("iMessage")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(.systemGray4), lineWidth: 1))

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white)

            // App tray bar
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.systemGray3))
                Image(systemName: "photo.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.systemGray3))
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.blue) // Scripture Share is active
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.systemGray3))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white)

            Divider()

            // Extension panel
            extensionContent()
                .frame(height: 280)
                .background(Color(.systemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.20), radius: 24, x: 0, y: 8)
    }
}

private struct ChatBubble: View {
    let text: String
    let isMe: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(isMe ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isMe ? Color.blue : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 220, alignment: isMe ? .trailing : .leading)
    }
}

// MARK: - Screenshot 1: Search

#Preview("1 – Search") {
    ScreenshotFrame(
        headline: "Find Any Verse\nInstantly",
        subhead: "Search 31,000+ KJV verses by keyword or reference",
        gradientStart: Color(red: 0.10, green: 0.25, blue: 0.60),
        gradientEnd:   Color(red: 0.05, green: 0.12, blue: 0.40)
    ) {
        SearchPreviewContent()
    }
}

private struct SearchPreviewContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // Fake search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("love")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Results
            List {
                verseRow(ref: "John 3:16", text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish…")
                verseRow(ref: "1 Corinthians 13:4", text: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up…")
                verseRow(ref: "Romans 8:38–39", text: "For I am persuaded, that neither death, nor life, nor angels… shall be able to separate us from the love of God…")
            }
            .listStyle(.plain)
        }
    }

    func verseRow(ref: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(ref)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 12))
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Screenshot 2: Browse

#Preview("2 – Browse") {
    ScreenshotFrame(
        headline: "Browse the\nComplete Bible",
        subhead: "Every book, chapter, and verse of the KJV — offline",
        gradientStart: Color(red: 0.05, green: 0.40, blue: 0.30),
        gradientEnd:   Color(red: 0.02, green: 0.22, blue: 0.18)
    ) {
        BrowsePreviewContent()
    }
}

private struct BrowsePreviewContent: View {
    let otBooks = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges"]
    let ntBooks = ["Matthew", "Mark", "Luke", "John", "Acts", "Romans"]

    var body: some View {
        List {
            Section {
                ForEach(otBooks, id: \.self) { book in
                    HStack {
                        Text(book).font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 1)
                }
            } header: {
                Text("Old Testament")
                    .font(.system(.caption, weight: .semibold))
            }
            Section {
                ForEach(ntBooks, id: \.self) { book in
                    HStack {
                        Text(book).font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 1)
                }
            } header: {
                Text("New Testament")
                    .font(.system(.caption, weight: .semibold))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Screenshot 3: Share a Verse

#Preview("3 – Share") {
    ScreenshotFrame(
        headline: "Share a Verse\nWith One Tap",
        subhead: "Preview the verse, then send it straight to your conversation",
        gradientStart: Color(red: 0.45, green: 0.10, blue: 0.65),
        gradientEnd:   Color(red: 0.25, green: 0.05, blue: 0.40)
    ) {
        SharePreviewContent()
    }
}

private struct SharePreviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("John 3:16")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 10) {
                Text("\"For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.\"")
                    .font(.system(size: 14))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("— John 3:16 (KJV)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                    } label: {
                        Label("Share", systemImage: "paperplane.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 16)

            Spacer()
        }
    }
}

// MARK: - Screenshot 4: Direct Entry

#Preview("4 – Direct Entry") {
    ScreenshotFrame(
        headline: "Type Any\nReference",
        subhead: "Just type "Psalm 23:1" and go — abbreviations work too",
        gradientStart: Color(red: 0.60, green: 0.30, blue: 0.05),
        gradientEnd:   Color(red: 0.38, green: 0.16, blue: 0.02)
    ) {
        DirectEntryPreviewContent()
    }
}

private struct DirectEntryPreviewContent: View {
    var body: some View {
        VStack(spacing: 12) {
            // Reference input
            HStack {
                Image(systemName: "text.cursor")
                    .foregroundStyle(.secondary)
                Text("Psalm 23:1")
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor, lineWidth: 1.5))
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Result card
            VStack(alignment: .leading, spacing: 8) {
                Text("\"The LORD is my shepherd; I shall not want.\"")
                    .font(.system(size: 14))
                    .italic()

                HStack {
                    Text("— Psalm 23:1 (KJV)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                    } label: {
                        Label("Share", systemImage: "paperplane.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 12)

            Spacer()
        }
    }
}

// MARK: - Screenshot 5: Recents

#Preview("5 – Recents") {
    ScreenshotFrame(
        headline: "Pick Up Where\nYou Left Off",
        subhead: "Recently shared verses are always one tap away",
        gradientStart: Color(red: 0.10, green: 0.35, blue: 0.10),
        gradientEnd:   Color(red: 0.05, green: 0.20, blue: 0.08)
    ) {
        RecentsPreviewContent()
    }
}

private struct RecentsPreviewContent: View {
    let recents: [(String, String)] = [
        ("John 3:16",        "For God so loved the world, that he gave his only begotten Son…"),
        ("Psalm 23:1",       "The LORD is my shepherd; I shall not want."),
        ("Philippians 4:13", "I can do all things through Christ which strengtheneth me."),
        ("Romans 8:28",      "And we know that all things work together for good to them that love God…"),
        ("Proverbs 3:5",     "Trust in the LORD with all thine heart; and lean not unto thine own understanding."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recently Shared")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)

            List {
                ForEach(recents, id: \.0) { ref, text in
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ref)
                                .font(.system(size: 12, weight: .semibold))
                            Text(text)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "paperplane")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
        }
    }
}
