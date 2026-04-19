import Foundation
import SwiftData

// MARK: - Time Horizon

enum TimeHorizon: String, CaseIterable {
    case week        = "7D"
    case month       = "1M"
    case threeMonths = "3M"
    case sixMonths   = "6M"
    case year        = "1Y"
    case allTime     = "All"

    var days: Int? {
        switch self {
        case .week:        return 7
        case .month:       return 30
        case .threeMonths: return 90
        case .sixMonths:   return 180
        case .year:        return 365
        case .allTime:     return nil
        }
    }

    var fetchLimit: Int {
        switch self {
        case .week:        return 50
        case .month:       return 100
        case .threeMonths: return 200
        case .sixMonths:   return 365
        case .year:        return 500
        case .allTime:     return 500
        }
    }

    var weeks: Int {
        switch self {
        case .week:        return 1
        case .month:       return 4
        case .threeMonths: return 13
        case .sixMonths:   return 26
        case .year:        return 52
        case .allTime:     return 52
        }
    }
}

// MARK: - Activity Feed

struct ActivityItem: Identifiable {
    let id: UUID
    let date: Date
    let icon: String
    let description: String
    let categoryName: String
    let logType: String   // "food" | "lifting" | "cardio" | "sleep" | "logEntry"
}

// MARK: - Chart Data Structures

struct DailyValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct WeeklyValue: Identifiable {
    let id = UUID()
    let weekLabel: String
    let value: Double
}

struct ExerciseProgress: Identifiable {
    let id = UUID()
    let exerciseName: String
    let date: Date
    let maxWeight: Double
}

// MARK: - Service

struct DashboardService {

    // MARK: - Streak & Today

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
               logs.contains(where: { calendar.isDateInToday($0.date) }) { return true }
            if let logs = try? context.fetch(FetchDescriptor<CardioEntry>()),
               logs.contains(where: { calendar.isDateInToday($0.date) }) { return true }
        case "Sleep":
            if let logs = try? context.fetch(FetchDescriptor<SleepLog>()) {
                return logs.contains { calendar.isDateInToday($0.date) }
            }
        default:
            break
        }

        return false
    }

    // MARK: - Recent Activity Feed

    static func recentActivity(
        in context: ModelContext,
        category: CategoryLevel? = nil,
        limit: Int
    ) -> [ActivityItem] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        var items: [ActivityItem] = []
        let categoryName = category?.name

        if categoryName == nil || categoryName == "Diet" {
            var d = FetchDescriptor<FoodLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            d.predicate = #Predicate { $0.date >= cutoff }
            d.fetchLimit = 50
            if let logs = try? context.fetch(d) {
                for log in logs {
                    items.append(ActivityItem(
                        id: log.id, date: log.date, icon: "fork.knife",
                        description: "🍽 \(log.name): \(Int(log.calories)) kcal, \(log.protein.formatted())g protein",
                        categoryName: "Diet", logType: "food"
                    ))
                }
            }
        }

        if categoryName == nil || categoryName == "Exercise" {
            var ld = FetchDescriptor<LiftingEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            ld.predicate = #Predicate { $0.date >= cutoff }
            ld.fetchLimit = 50
            if let logs = try? context.fetch(ld) {
                for log in logs {
                    items.append(ActivityItem(
                        id: log.id, date: log.date, icon: "figure.run",
                        description: "💪 \(log.exerciseName): \(log.sets.count) sets",
                        categoryName: "Exercise", logType: "lifting"
                    ))
                }
            }
            var cd = FetchDescriptor<CardioEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            cd.predicate = #Predicate { $0.date >= cutoff }
            cd.fetchLimit = 50
            if let logs = try? context.fetch(cd) {
                for log in logs {
                    items.append(ActivityItem(
                        id: log.id, date: log.date, icon: "figure.run",
                        description: "🏃 \(log.type): \(log.durationMinutes.formatted()) min",
                        categoryName: "Exercise", logType: "cardio"
                    ))
                }
            }
        }

        if categoryName == nil || categoryName == "Sleep" {
            var sd = FetchDescriptor<SleepLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            sd.predicate = #Predicate { $0.date >= cutoff }
            sd.fetchLimit = 50
            if let logs = try? context.fetch(sd) {
                for log in logs {
                    items.append(ActivityItem(
                        id: log.id, date: log.date, icon: "bed.double",
                        description: "😴 \(log.hoursSlept.formatted()) hours sleep",
                        categoryName: "Sleep", logType: "sleep"
                    ))
                }
            }
        }

        var led = FetchDescriptor<LogEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        led.predicate = #Predicate { $0.date >= cutoff }
        led.fetchLimit = 50
        if let logs = try? context.fetch(led) {
            for log in logs {
                let logCategoryID = log.subMetric?.goal?.category?.id
                if let category, logCategoryID != category.id { continue }
                let icon = log.subMetric?.goal?.category?.icon ?? "star"
                let catName = log.subMetric?.goal?.category?.name ?? "Custom"
                let metricName = log.subMetric?.name ?? "Entry"
                let unit = log.subMetric?.unit ?? ""
                let isChecklist = log.subMetric?.isChecklistItem ?? false
                let desc = isChecklist
                    ? "✅ \(metricName) completed"
                    : "\(metricName): \(log.value.formatted()) \(unit)"
                items.append(ActivityItem(
                    id: log.id, date: log.date, icon: icon,
                    description: desc, categoryName: catName, logType: "logEntry"
                ))
            }
        }

        return Array(items.sorted { $0.date > $1.date }.prefix(limit))
    }

    // MARK: - Chart Data

    static func dailyCalories(horizon: TimeHorizon, in context: ModelContext) -> [DailyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var descriptor = FetchDescriptor<FoodLog>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit

        let logs = (try? context.fetch(descriptor)) ?? []

        var byDay: [Date: Double] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            byDay[day, default: 0] += log.calories
        }

        if let days = horizon.days {
            return (0..<days).compactMap { i -> DailyValue? in
                guard let day = calendar.date(byAdding: .day, value: i - (days - 1), to: today) else { return nil }
                let dayStart = calendar.startOfDay(for: day)
                return DailyValue(date: dayStart, value: byDay[dayStart] ?? 0, label: dateLabel(day, for: horizon))
            }
        } else {
            return byDay.map { DailyValue(date: $0.key, value: $0.value, label: dateLabel($0.key, for: horizon)) }
                .sorted { $0.date < $1.date }
        }
    }

    static func dailyProtein(horizon: TimeHorizon, in context: ModelContext) -> [DailyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var descriptor = FetchDescriptor<FoodLog>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit

        let logs = (try? context.fetch(descriptor)) ?? []

        var byDay: [Date: Double] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            byDay[day, default: 0] += log.protein
        }

        if let days = horizon.days {
            return (0..<days).compactMap { i -> DailyValue? in
                guard let day = calendar.date(byAdding: .day, value: i - (days - 1), to: today) else { return nil }
                let dayStart = calendar.startOfDay(for: day)
                return DailyValue(date: dayStart, value: byDay[dayStart] ?? 0, label: dateLabel(day, for: horizon))
            }
        } else {
            return byDay.map { DailyValue(date: $0.key, value: $0.value, label: dateLabel($0.key, for: horizon)) }
                .sorted { $0.date < $1.date }
        }
    }

    static func sleepPerNight(horizon: TimeHorizon, in context: ModelContext) -> [DailyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var descriptor = FetchDescriptor<SleepLog>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit

        let logs = (try? context.fetch(descriptor)) ?? []

        var byDay: [Date: Double] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            byDay[day] = log.hoursSlept
        }

        if let days = horizon.days {
            return (0..<days).compactMap { i -> DailyValue? in
                guard let day = calendar.date(byAdding: .day, value: i - (days - 1), to: today) else { return nil }
                let dayStart = calendar.startOfDay(for: day)
                return DailyValue(date: dayStart, value: byDay[dayStart] ?? 0, label: dateLabel(day, for: horizon))
            }
        } else {
            return byDay.map { DailyValue(date: $0.key, value: $0.value, label: dateLabel($0.key, for: horizon)) }
                .sorted { $0.date < $1.date }
        }
    }

    static func weightOverTime(horizon: TimeHorizon, in context: ModelContext) -> [DailyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var descriptor = FetchDescriptor<WeightLog>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit

        let logs = (try? context.fetch(descriptor)) ?? []
        return logs.map { log in
            DailyValue(
                date: calendar.startOfDay(for: log.date),
                value: log.weightLbs,
                label: dateLabel(log.date, for: horizon)
            )
        }
    }

    static func liftingDaysPerWeek(horizon: TimeHorizon, in context: ModelContext) -> [WeeklyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weeks = horizon.weeks

        var descriptor = FetchDescriptor<LiftingEntry>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit
        let logs = (try? context.fetch(descriptor)) ?? []

        return (0..<weeks).map { weekOffset -> WeeklyValue in
            let offset = -(weeks - 1 - weekOffset)
            let weekAnchor = calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekAnchor)
            let weekStart = calendar.date(from: comps) ?? weekAnchor
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

            var loggedDays = Set<Date>()
            for log in logs {
                let logDay = calendar.startOfDay(for: log.date)
                if logDay >= weekStart && logDay <= min(weekEnd, today) {
                    loggedDays.insert(logDay)
                }
            }

            let label: String
            switch offset {
            case 0:  label = "This wk"
            case -1: label = "Last wk"
            default: label = "\(-offset)w ago"
            }
            return WeeklyValue(weekLabel: label, value: Double(loggedDays.count))
        }
    }

    static func cardioDaysPerWeek(horizon: TimeHorizon, in context: ModelContext) -> [WeeklyValue] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weeks = horizon.weeks

        var descriptor = FetchDescriptor<CardioEntry>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit
        let logs = (try? context.fetch(descriptor)) ?? []

        return (0..<weeks).map { weekOffset -> WeeklyValue in
            let offset = -(weeks - 1 - weekOffset)
            let weekAnchor = calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekAnchor)
            let weekStart = calendar.date(from: comps) ?? weekAnchor
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

            var loggedDays = Set<Date>()
            for log in logs {
                let logDay = calendar.startOfDay(for: log.date)
                if logDay >= weekStart && logDay <= min(weekEnd, today) {
                    loggedDays.insert(logDay)
                }
            }

            let label: String
            switch offset {
            case 0:  label = "This wk"
            case -1: label = "Last wk"
            default: label = "\(-offset)w ago"
            }
            return WeeklyValue(weekLabel: label, value: Double(loggedDays.count))
        }
    }

    static func exerciseProgress(horizon: TimeHorizon, in context: ModelContext) -> [ExerciseProgress] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var descriptor = FetchDescriptor<LiftingEntry>(sortBy: [SortDescriptor(\.date)])
        if let days = horizon.days {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            descriptor.predicate = #Predicate { $0.date >= startDate }
        }
        descriptor.fetchLimit = horizon.fetchLimit

        let logs = (try? context.fetch(descriptor)) ?? []
        let grouped = Dictionary(grouping: logs, by: { $0.exerciseName })

        var result: [ExerciseProgress] = []
        for (name, entries) in grouped {
            for entry in entries {
                let maxWeight = entry.sets.map(\.weightKg).max() ?? 0
                result.append(ExerciseProgress(exerciseName: name, date: entry.date, maxWeight: maxWeight))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    static func completionRate(for subMetric: SubMetric, period: String) -> Double {
        let calendar = Calendar.current

        if period == "daily" {
            return subMetric.logs.contains { calendar.isDateInToday($0.date) } ? 1.0 : 0.0
        }

        let today = calendar.startOfDay(for: Date())
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let weekStart = calendar.date(from: comps) else { return 0 }
        let daysElapsed = max(1, (calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0) + 1)

        var loggedDays = Set<Date>()
        for log in subMetric.logs {
            let logDay = calendar.startOfDay(for: log.date)
            if logDay >= weekStart && logDay <= today {
                loggedDays.insert(logDay)
            }
        }
        return Double(loggedDays.count) / Double(daysElapsed)
    }

    // MARK: - Maintenance

    static func clearStaleData(in context: ModelContext) {
        // TODO: Delete records older than 1 year.
        // Candidates: FoodLog, LiftingEntry, CardioEntry, SleepLog, WeightLog, LogEntry.
    }

    // MARK: - Private

    private static func dateLabel(_ date: Date, for horizon: TimeHorizon) -> String {
        if case .week = horizon {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

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
