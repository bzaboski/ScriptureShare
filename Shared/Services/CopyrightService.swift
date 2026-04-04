import Foundation

/// Provides copyright and attribution text for Bible translations.
/// Ensures proper attribution per each translation's licensing requirements.
public struct CopyrightService {

    /// Full copyright/attribution text for display in settings or about screens.
    public static func attribution(for translation: Translation) -> String {
        translation.copyright
    }

    /// Short inline attribution for compact display (e.g., verse cards).
    public static func shortAttribution(for translation: Translation) -> String {
        translation.shortCopyright
    }

    /// Attribution text formatted for shared messages.
    /// Includes the minimum required attribution per translation license.
    public static func sharingAttribution(for translation: Translation) -> String {
        switch translation {
        case .kjv:
            return "(KJV)"
        case .esv:
            return "(ESV)"
        case .nlt:
            return "(NLT)"
        }
    }

    /// All copyright notices for currently available translations.
    /// Suitable for display in a settings/about section.
    public static func allAttributions() -> [(translation: Translation, text: String)] {
        Translation.available.map { ($0, $0.copyright) }
    }
}
