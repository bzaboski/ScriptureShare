import SwiftUI

/// Main host app view — shown after onboarding is complete.
struct MainAppView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)

                    Text("Scripture Share")
                        .font(.largeTitle.bold())

                    Text("Share Bible verses directly in Messages.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // How to use
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        InstructionRow(
                            step: "1",
                            icon: "message.fill",
                            text: "Open a conversation in Messages"
                        )
                        InstructionRow(
                            step: "2",
                            icon: "square.grid.2x2",
                            text: "Tap the App Store icon, then find Scripture Share"
                        )
                        InstructionRow(
                            step: "3",
                            icon: "magnifyingglass",
                            text: "Browse, search, or type a reference"
                        )
                        InstructionRow(
                            step: "4",
                            icon: "paperplane.fill",
                            text: "Tap Share to insert the verse"
                        )
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 32)
            }
        }
        .navigationTitle("Scripture Share")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let step: String
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
            }

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MainAppView()
        .modelContainer(UserSettings.sharedModelContainer)
}
