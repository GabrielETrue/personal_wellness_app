import SwiftUI

struct ClaudeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .shadow(color: AppTheme.accentPurple.opacity(0.5), radius: 20)
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AppTheme.accentPurple.opacity(0.6), radius: 8)
                    }

                    Text("Claude AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.xpGradient)

                    Text("Coming soon")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Claude")
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ClaudeView()
        .preferredColorScheme(.dark)
}
