//
//  Personal_Wellness_AppApp.swift
//  Personal Wellness App
//
//  Created by Gabriel True on 4/18/26.
//

import SwiftUI
import SwiftData

@main
struct Personal_Wellness_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PlayerProfile.self,
            CategoryLevel.self,
            LevelEvent.self,
            Goal.self,
            SubMetric.self,
            LogEntry.self,
            FoodLog.self,
            CustomNutrient.self,
            LiftingEntry.self,
            LiftingSet.self,
            CardioEntry.self,
            SleepLog.self,
            JournalEntry.self,
            AIInsight.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await seedDefaultDataIfNeeded() }
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func seedDefaultDataIfNeeded() async {
        let context = sharedModelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<PlayerProfile>())) ?? 0
        guard count == 0 else { return }

        let player = PlayerProfile()
        let categories: [(name: String, icon: String)] = [
            ("Diet", "fork.knife"),
            ("Exercise", "figure.run"),
            ("Sleep", "bed.double"),
            ("Custom", "star"),
        ]
        for cat in categories {
            let categoryLevel = CategoryLevel(name: cat.name, icon: cat.icon)
            categoryLevel.player = player
            player.categoryLevels.append(categoryLevel)
            context.insert(categoryLevel)
        }
        context.insert(player)
        try? context.save()
    }
}
