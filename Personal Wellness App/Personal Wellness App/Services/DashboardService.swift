import Foundation
import SwiftData

struct ActivityItem: Identifiable {
    let id: UUID
    let date: Date
    let icon: String
    let description: String
    let categoryName: String
}

struct DashboardService {

    static func streak(for category: CategoryLevel, in context: ModelContext) -> Int {
        let dates = loggedDates(for: category, in: context)
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while dates.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }
        return streak
    }

    static func hasLoggedToday(for category: CategoryLevel, in context: ModelContext) -> Bool {
        let calendar = Calendar.current

        for goal in category.goals {
            for metric in goal.subMetrics {
                if metric.logs.contains(where: { calendar.isDateInToday($0.date) }) {
                    return true
                }
            }
        }

        switch category.name {
        case "Diet":
            if let logs = try? context.fetch(FetchDescriptor<FoodLog>()) {
                return logs.contains { calendar.isDateInToday($0.date) }
            }
        case "Exercise":
            if let logs = try? context.fetch(FetchDescriptor<LiftingEntry>()),
               logs.contains(where: { calendar.isDateInToday($0.date) }) {
                return true
            }
            if let logs = try? context.fetch(FetchDescriptor<CardioEntry>()),
               logs.contains(where: { calendar.isDateInToday($0.date) }) {
                return true
            }
        case "Sleep":
            if let logs = try? context.fetch(FetchDescriptor<SleepLog>()) {
                return logs.contains { calendar.isDateInToday($0.date) }
            }
        default:
            break
        }

        return false
    }

    static func recentActivity(in context: ModelContext, limit: Int) -> [ActivityItem] {
        var items: [ActivityItem] = []

        if let logs = try? context.fetch(FetchDescriptor<FoodLog>()) {
            for log in logs {
                items.append(ActivityItem(
                    id: log.id,
                    date: log.date,
                    icon: "fork.knife",
                    description: "🍽 \(log.name): \(Int(log.calories)) kcal, \(log.protein.formatted())g protein",
                    categoryName: "Diet"
                ))
            }
        }

        if let logs = try? context.fetch(FetchDescriptor<LiftingEntry>()) {
            for log in logs {
                items.append(ActivityItem(
                    id: log.id,
                    date: log.date,
                    icon: "figure.run",
                    description: "💪 \(log.exerciseName): \(log.sets.count) sets",
                    categoryName: "Exercise"
                ))
            }
        }

        if let logs = try? context.fetch(FetchDescriptor<CardioEntry>()) {
            for log in logs {
                items.append(ActivityItem(
                    id: log.id,
                    date: log.date,
                    icon: "figure.run",
                    description: "🏃 \(log.type): \(log.durationMinutes.formatted()) min",
                    categoryName: "Exercise"
                ))
            }
        }

        if let logs = try? context.fetch(FetchDescriptor<SleepLog>()) {
            for log in logs {
                items.append(ActivityItem(
                    id: log.id,
                    date: log.date,
                    icon: "bed.double",
                    description: "😴 \(log.hoursSlept.formatted()) hours sleep",
                    categoryName: "Sleep"
                ))
            }
        }

        if let logs = try? context.fetch(FetchDescriptor<LogEntry>()) {
            for log in logs {
                let icon = log.subMetric?.goal?.category?.icon ?? "star"
                let catName = log.subMetric?.goal?.category?.name ?? "Custom"
                let metricName = log.subMetric?.name ?? "Entry"
                let unit = log.subMetric?.unit ?? ""
                items.append(ActivityItem(
                    id: log.id,
                    date: log.date,
                    icon: icon,
                    description: "\(metricName): \(log.value.formatted()) \(unit)",
                    categoryName: catName
                ))
            }
        }

        return Array(items.sorted { $0.date > $1.date }.prefix(limit))
    }

    // MARK: - Private

    private static func loggedDates(for category: CategoryLevel, in context: ModelContext) -> Set<Date> {
        let calendar = Calendar.current
        var dates = Set<Date>()

        for goal in category.goals {
            for metric in goal.subMetrics {
                for log in metric.logs {
                    dates.insert(calendar.startOfDay(for: log.date))
                }
            }
        }

        switch category.name {
        case "Diet":
            if let logs = try? context.fetch(FetchDescriptor<FoodLog>()) {
                logs.forEach { dates.insert(calendar.startOfDay(for: $0.date)) }
            }
        case "Exercise":
            if let logs = try? context.fetch(FetchDescriptor<LiftingEntry>()) {
                logs.forEach { dates.insert(calendar.startOfDay(for: $0.date)) }
            }
            if let logs = try? context.fetch(FetchDescriptor<CardioEntry>()) {
                logs.forEach { dates.insert(calendar.startOfDay(for: $0.date)) }
            }
        case "Sleep":
            if let logs = try? context.fetch(FetchDescriptor<SleepLog>()) {
                logs.forEach { dates.insert(calendar.startOfDay(for: $0.date)) }
            }
        default:
            break
        }

        return dates
    }
}
