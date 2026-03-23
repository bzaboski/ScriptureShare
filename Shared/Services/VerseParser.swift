import Foundation

/// Parses a reference string like "John 3:16", "Gen 1:1", or "1 Cor 13:4-7" into a VerseReference.
public struct VerseParser {

    // Maps abbreviations (lowercased) → canonical book name
    static let abbreviationMap: [String: String] = {
        var map: [String: String] = [:]
        for (canonical, aliases) in bookAliases {
            for alias in aliases {
                map[alias.lowercased()] = canonical
            }
            map[canonical.lowercased()] = canonical
        }
        return map
    }()

    // Book name → list of accepted abbreviations
    static let bookAliases: [(String, [String])] = [
        ("Genesis",          ["gen", "ge", "gn"]),
        ("Exodus",           ["exod", "ex", "exo"]),
        ("Leviticus",        ["lev", "le", "lv"]),
        ("Numbers",          ["num", "nu", "nm", "nb"]),
        ("Deuteronomy",      ["deut", "de", "dt"]),
        ("Joshua",           ["josh", "jos", "jsh"]),
        ("Judges",           ["judg", "jdg", "jg", "jdgs"]),
        ("Ruth",             ["ruth", "rth", "ru"]),
        ("1 Samuel",         ["1sam", "1sa", "1s", "1sm"]),
        ("2 Samuel",         ["2sam", "2sa", "2s", "2sm"]),
        ("1 Kings",          ["1kgs", "1ki", "1k"]),
        ("2 Kings",          ["2kgs", "2ki", "2k"]),
        ("1 Chronicles",     ["1chr", "1ch", "1chron"]),
        ("2 Chronicles",     ["2chr", "2ch", "2chron"]),
        ("Ezra",             ["ezra", "ez"]),
        ("Nehemiah",         ["neh", "ne"]),
        ("Esther",           ["esth", "est", "es"]),
        ("Job",              ["job", "jb"]),
        ("Psalms",           ["ps", "psa", "psalm", "pss"]),
        ("Proverbs",         ["prov", "pro", "prv", "pr"]),
        ("Ecclesiastes",     ["eccl", "ecc", "ec", "qoh"]),
        ("Song of Solomon",  ["song", "sos", "sg", "sol", "ss"]),
        ("Isaiah",           ["isa", "is"]),
        ("Jeremiah",         ["jer", "je", "jr"]),
        ("Lamentations",     ["lam", "la"]),
        ("Ezekiel",          ["ezek", "eze", "ezk"]),
        ("Daniel",           ["dan", "da", "dn"]),
        ("Hosea",            ["hos", "ho"]),
        ("Joel",             ["joel", "jl"]),
        ("Amos",             ["amos", "am"]),
        ("Obadiah",          ["obad", "ob"]),
        ("Jonah",            ["jonah", "jon", "jnh"]),
        ("Micah",            ["mic", "mc"]),
        ("Nahum",            ["nah", "na"]),
        ("Habakkuk",         ["hab", "hb"]),
        ("Zephaniah",        ["zeph", "zep", "zp"]),
        ("Haggai",           ["hag", "hg"]),
        ("Zechariah",        ["zech", "zec", "zc"]),
        ("Malachi",          ["mal", "ml"]),
        ("Matthew",          ["matt", "mat", "mt"]),
        ("Mark",             ["mark", "mar", "mrk", "mk", "mr"]),
        ("Luke",             ["luke", "luk", "lk"]),
        ("John",             ["john", "jhn", "jn"]),
        ("Acts",             ["acts", "ac"]),
        ("Romans",           ["rom", "ro", "rm"]),
        ("1 Corinthians",    ["1cor", "1co"]),
        ("2 Corinthians",    ["2cor", "2co"]),
        ("Galatians",        ["gal", "ga"]),
        ("Ephesians",        ["eph", "ephes"]),
        ("Philippians",      ["phil", "php", "pp"]),
        ("Colossians",       ["col", "co"]),
        ("1 Thessalonians",  ["1thess", "1th", "1ths"]),
        ("2 Thessalonians",  ["2thess", "2th", "2ths"]),
        ("1 Timothy",        ["1tim", "1ti", "1tm"]),
        ("2 Timothy",        ["2tim", "2ti", "2tm"]),
        ("Titus",            ["titus", "tit", "ti"]),
        ("Philemon",         ["philem", "phm", "pm"]),
        ("Hebrews",          ["heb", "he"]),
        ("James",            ["jas", "jm"]),
        ("1 Peter",          ["1pet", "1pe", "1pt", "1p"]),
        ("2 Peter",          ["2pet", "2pe", "2pt", "2p"]),
        ("1 John",           ["1jn", "1jo", "1j"]),
        ("2 John",           ["2jn", "2jo", "2j"]),
        ("3 John",           ["3jn", "3jo", "3j"]),
        ("Jude",             ["jude", "jud"]),
        ("Revelation",       ["rev", "re", "rv"]),
    ]

    /// Parse a reference string into a VerseReference, or nil if parsing fails.
    /// Supports:
    ///   - Single verse:  "John 3:16", "Gen 1:1", "Ps 23:1"
    ///   - Verse range:   "1 Corinthians 13:4-7", "Psalm 23:1-6", "John 3:16-17"
    public static func parse(_ input: String) -> VerseReference? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Pattern supports optional leading digit (e.g., "1 "), book name words, then chapter:verse[-endVerse]
        // Group 1: optional leading number (e.g. "1 ")
        // Group 2: book name word(s)
        // Group 3: chapter
        // Group 4: start verse
        // Group 5: optional end verse (for ranges)
        let pattern = #"^(\d\s+)?([a-zA-Z]+(?:\s+[a-zA-Z]+)*)\s+(\d+):(\d+)(?:-(\d+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed))
        else { return nil }

        func group(_ i: Int) -> String? {
            let range = match.range(at: i)
            guard range.location != NSNotFound,
                  let swiftRange = Range(range, in: trimmed)
            else { return nil }
            return String(trimmed[swiftRange]).trimmingCharacters(in: .whitespaces)
        }

        let leadingNum = group(1) ?? ""
        let bookPart = group(2) ?? ""
        guard let chapterStr = group(3), let chapter = Int(chapterStr),
              let verseStr = group(4), let verse = Int(verseStr)
        else { return nil }

        let endVerse: Int? = group(5).flatMap { Int($0) }

        let rawBook: String
        if leadingNum.isEmpty {
            rawBook = bookPart.trimmingCharacters(in: .whitespaces)
        } else {
            rawBook = "\(leadingNum) \(bookPart)"
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
        }
        guard let canonical = resolve(rawBook) else { return nil }

        // Validate range order
        if let end = endVerse, end < verse { return nil }

        return VerseReference(bookName: canonical, chapter: chapter, verse: verse, endVerse: endVerse)
    }

    /// Resolve a raw book string (name or abbreviation) to a canonical book name.
    public static func resolve(_ raw: String) -> String? {
        abbreviationMap[raw.lowercased()]
    }

    // MARK: - Superscript formatting

    /// Convert an integer to Unicode superscript digits.
    public static func superscript(_ n: Int) -> String {
        let superscriptDigits: [Character] = ["⁰","¹","²","³","⁴","⁵","⁶","⁷","⁸","⁹"]
        return String(n).compactMap { ch in
            guard let d = ch.wholeNumberValue else { return nil }
            return superscriptDigits[d]
        }.map { String($0) }.joined()
    }

    /// Format an array of Verse objects as a single string with inline superscript verse numbers.
    /// Example: "¹⁶ For God so loved the world... ¹⁷ For God sent not his Son..."
    public static func formatRange(_ verses: [any VerseProtocol]) -> String {
        verses.map { v in
            "\(superscript(v.verseNumber)) \(v.text)"
        }.joined(separator: " ")
    }
}

/// Protocol so formatRange can work with both Verse and mock types in tests.
public protocol VerseProtocol {
    var verseNumber: Int { get }
    var text: String { get }
}

extension Verse: VerseProtocol {}
