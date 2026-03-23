import SwiftUI
import SwiftData

@main
struct ScriptureShareApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
        .modelContainer(UserSettings.sharedModelContainer)
    }
}
