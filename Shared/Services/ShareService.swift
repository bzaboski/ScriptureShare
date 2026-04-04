import Foundation

/// Formats verse text for sharing in iMessage.
/// Used by both the host app and iMessage extension.
public struct ShareService {

    /// Format a single verse for insertion into iMessage.
    /// Format: verse text + newline + '— Reference (Translation)'
    public static func shareText(for verse: Verse) -> String {
        let attribution = CopyrightService.sharingAttribution(
            for: Translation.from(verse.translation)
        )
        return "\"\(verse.text)\"\n— \(verse.reference) \(attribution)"
    }

    /// Format a verse range for insertion into iMessage.
    /// Verse numbers are included inline as superscript Unicode characters.
    /// Format: ¹⁶ text ¹⁷ text + newline + '— Book Ch:V-EndV (Translation)'
    public static func shareText(for verses: [Verse]) -> String {
        guard let first = verses.first, let last = verses.last else { return "" }
        if verses.count == 1 {
            return shareText(for: first)
        }
        let rangeText = VerseParser.formatRange(verses)
        let reference = "\(first.bookName) \(first.chapterNumber):\(first.verseNumber)-\(last.verseNumber)"
        let attribution = CopyrightService.sharingAttribution(
            for: Translation.from(first.translation)
        )
        return "\"\(rangeText)\"\n— \(reference) \(attribution)"
    }
}
