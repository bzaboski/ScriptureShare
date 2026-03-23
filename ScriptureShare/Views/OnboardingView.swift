import SwiftUI

/// Multi-screen onboarding shown on first launch.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "book.closed.fill",
            imageColor: .blue,
            title: "Scripture Share",
            body: "Search and share Bible verses directly in your iMessage conversations. The full King James Bible — always with you, always offline."
        ),
        OnboardingPage(
            systemImage: "message.fill",
            imageColor: .green,
            title: "Find It in Messages",
            body: "Open a conversation in Messages, then tap the App Store icon in the toolbar. Tap the grid icon and find Scripture Share to activate it."
        ),
        OnboardingPage(
            systemImage: "paperplane.fill",
            imageColor: .purple,
            title: "Share in One Tap",
            body: "Browse by book, type a reference, or search by keyword. Tap Share and the verse appears in your compose field — ready to send."
        ),
    ]

    var body: some View {
        if hasCompletedOnboarding {
            MainAppView()
        } else {
            onboardingFlow
        }
    }

    private var onboardingFlow: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            // Navigation buttons
            VStack(spacing: 12) {
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                } else {
                    Button("Get Started") {
                        hasCompletedOnboarding = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                }

                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 48)
            .padding(.top, 16)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let systemImage: String
    let imageColor: Color
    let title: String
    let body: String
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(page.imageColor)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(UserSettings.sharedModelContainer)
}
