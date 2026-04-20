import SwiftUI

struct ContentView: View {
    @State private var quickLogPresented = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.075, green: 0.098, blue: 0.118, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                NavigationStack {
                    DashboardView()
                }
                .tabItem { Label("Dashboard", systemImage: "house") }
                .toolbarBackground(AppTheme.backgroundSecondary, for: .tabBar)

                NavigationStack {
                    GoalsView()
                }
                .tabItem { Label("Goals", systemImage: "target") }

                NavigationStack {
                    JournalView()
                }
                .tabItem { Label("Journal", systemImage: "book") }

                ClaudeView()
                    .tabItem { Label("Claude", systemImage: "sparkles") }
            }
            .tint(AppTheme.accentBlue)
            .sheet(isPresented: $quickLogPresented) {
                QuickLogView()
            }

            if !quickLogPresented {
                QuickLogButton(isPresented: $quickLogPresented)
                    .padding(.trailing, 20)
                    .padding(.bottom, 96)
            }
        }
    }
}

#Preview {
    ContentView()
}
