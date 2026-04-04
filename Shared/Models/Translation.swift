import Foundation

/// Represents a Bible translation available in the app.
/// KJV is bundled locally; ESV and NLT require API keys.
public enum Translation: String, CaseIterable, Identifiable, Codable {
    case kjv = "KJV"
    case esv = "ESV"
    case nlt = "NLT"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .kjv: return "KJV"
        case .esv: return "ESV"
        case .nlt: return "NLT"
        }
    }

    public var fullName: String {
        switch self {
        case .kjv: return "King James Version"
        case .esv: return "English Standard Version"
        case .nlt: return "New Living Translation"
        }
    }

    /// Full copyright/attribution text required by each translation's license.
    public var copyright: String {
        switch self {
        case .kjv:
            return "King James Version (1611). Public domain."
        case .esv:
            return "Scripture quotations are from the ESV\u{00AE} Bible (The Holy Bible, English Standard Version\u{00AE}), \u{00A9} 2001 by Crossway, a publishing ministry of Good News Publishers. Used by permission. All rights reserved."
        case .nlt:
            return "Scripture quotations are taken from the Holy Bible, New Living Translation, \u{00A9} 1996, 2004, 2015 by Tyndale House Foundation. Used by permission of Tyndale House Publishers, Inc., Carol Stream, Illinois 60188. All rights reserved."
        }
    }

    /// Short attribution for inline display (e.g. in shared messages).
    public var shortCopyright: String {
        switch self {
        case .kjv: return "(KJV)"
        case .esv: return "(ESV)"
        case .nlt: return "(NLT)"
        }
    }

    /// Whether the translation data is bundled locally (no network needed).
    public var isLocal: Bool { self == .kjv }

    /// Whether the translation is available for use (API key configured or local).
    public var isAvailable: Bool {
        switch self {
        case .kjv: return true
        case .esv: return APIConfig.esvAPIKey != nil
        case .nlt: return APIConfig.nltAPIKey != nil
        }
    }

    /// Initialize from a raw string, defaulting to KJV if unrecognized.
    public static func from(_ string: String) -> Translation {
        Translation(rawValue: string.uppercased()) ?? .kjv
    }

    /// All translations that are currently available (have API keys or are local).
    public static var available: [Translation] {
        allCases.filter { $0.isAvailable }
    }
}
