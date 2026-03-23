import Foundation
import SwiftData

@Model
public final class UserSettings {
    public var preferredTranslation: String
    public var recentVerseIDs: [Int]

    public init(preferredTranslation: String = "KJV", recentVerseIDs: [Int] = []) {
        self.preferredTranslation = preferredTranslation
        self.recentVerseIDs = recentVerseIDs
    }

    public static var sharedModelContainer: ModelContainer = {
        let schema = Schema([UserSettings.self])
        let config = ModelConfiguration(
            groupContainer: .identifier("group.com.bzaboski.scriptureshare")
        )
        return try! ModelContainer(for: schema, configurations: config)
    }()
}
