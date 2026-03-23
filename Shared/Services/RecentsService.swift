import Foundation
import SwiftData

/// Manages the list of recently shared verse IDs in UserSettings.
public struct RecentsService {

    public static let maxRecents = 20

    /// Add a verse ID to the recents list.
    /// - Moves existing entry to top if already present (deduplication).
    /// - Caps the list at `maxRecents`.
    public static func addRecent(verseID: Int, to settings: UserSettings) {
        var ids = settings.recentVerseIDs
        // Remove existing occurrence (for deduplication / move-to-top)
        ids.removeAll { $0 == verseID }
        // Prepend
        ids.insert(verseID, at: 0)
        // Cap at max
        if ids.count > maxRecents {
            ids = Array(ids.prefix(maxRecents))
        }
        settings.recentVerseIDs = ids
    }

    /// Clear all recent verses.
    public static func clearRecents(in settings: UserSettings) {
        settings.recentVerseIDs = []
    }
}
