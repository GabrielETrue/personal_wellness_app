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
            WeightLog.self,
        ])

        func makeContainer() throws -> ModelContainer {
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        }

        do {
            return try makeContainer()
        } catch {
            print("ModelContainer init failed, attempting store reset: \(error)")
            if let storeURL = URL.applicationSupportDirectory
                .appending(path: "default.store", directoryHint: .notDirectory) as URL? {
                let fm = FileManager.default
                for suffix in ["", "-shm", "-wal"] {
                    let path = storeURL.path + suffix
                    if fm.fileExists(atPath: path) {
                        try? fm.removeItem(atPath: path)
                    }
                }
            }
            do {
                return try makeContainer()
            } catch {
                fatalError("Could not create ModelContainer after store reset: \(error)")
            }
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
        do {
            let count = try context.fetchCount(FetchDescriptor<PlayerProfile>())
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
            try context.save()
        } catch {
            print("seedDefaultDataIfNeeded failed: \(error)")
        }
    }
}
