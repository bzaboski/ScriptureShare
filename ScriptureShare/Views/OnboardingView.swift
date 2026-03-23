import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Scripture Share")
                .font(.largeTitle.bold())

            Text("Search and share Bible verses directly in Messages.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Open Messages to get started.\nTap the app drawer and select Scripture Share.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

#Preview {
    OnboardingView()
}
