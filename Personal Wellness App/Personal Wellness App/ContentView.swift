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
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            NavigationStack {
                GoalsView()
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            NavigationStack {
                JournalView()
            }
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
