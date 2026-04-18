//
//  ContentView.swift
//  Personal Wellness App
//
//  Created by Gabriel True on 4/18/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
            ClaudeView()
                .tabItem {
                    Label("Claude", systemImage: "sparkles")
                }
        }
    }
}

#Preview {
    ContentView()
}
