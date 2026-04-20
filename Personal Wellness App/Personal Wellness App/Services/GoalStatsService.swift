import Foundation
import SwiftData

// MARK: - Stat Structs

struct SubMetricStats {
    let name: String
    let unit: String
    let targetValue: Double
    let type: String
    let today: Double?
    let yesterday: Double?
    let twoDaysAgo: Double?
    let threeDaysAgo: Double?
    let fourDaysAgo: Double?
    let sevenDayAverage: Double?
    let thirtyDayAverage: Double?
    let bestValue: Double?
    let trend: String
}

struct GoalStats {
    let goalName: String
    let category: String
    let frequency: String
    let xpValue: Int
    let currentStreak: Int
    let longestStreak: Int
    let targetDate: String
    let daysActive: Int
    let daysRemaining: Int?
    let subMetricStats: [SubMetricStats]
    let weekdayPerformance: [String: Double]
    let velocityCurrentWeek: Double
    let velocityPreviousWeek: Double
    let velocityTrend: String
}

struct CategoryStats {
    let categoryName: String
    let level: Int
    let xp: Int
    let currentStreak: Int
    let goalStats: [GoalStats]
}

struct DietStats {
    let todayCalories: Double?
    let yesterdayCalories: Double?
    let twoDaysAgoCalories: Double?
    let threeDaysAgoCalories: Double?
    let fourDaysAgoCalories: Double?
    let sevenDayAverageCalories: Double?
    let thirtyDayAverageCalories: Double?
    let todayProtein: Double?
    let yesterdayProtein: Double?
    let twoDaysAgoProtein: Double?
    let threeDaysAgoProtein: Double?
    let fourDaysAgoProtein: Double?
    let sevenDayAverageProtein: Double?
    let thirtyDayAverageProtein: Double?
    let calorieTrend: String
    let proteinTrend: String
}

struct ExerciseStats {
    let liftingDaysThisWeek: Int
    let liftingDaysLastWeek: Int
    let cardioDaysThisWeek: Int
    let cardioDaysLastWeek: Int
    let currentLiftingStreak: Int
    let currentCardioStreak: Int
    let recentPRs: [String]
    let totalSetsThisWeek: Int
    let totalCardioMinutesThisWeek: Double
}

struct SleepStats {
    let lastNight: Double?
    let twoDaysAgo: Double?
    let threeDaysAgo: Double?
    let fourDaysAgo: Double?
    let fiveDaysAgo: Double?
    let sevenDayAverage: Double?
    let thirtyDayAverage: Double?
    let trend: String
    let goalHours: Double
}

struct WeightStats {
    let current: Double?
    let sevenDaysAgo: Double?
    let thirtyDaysAgo: Double?
    let trend: String
    let weeklyChangeRate: Double?
}

struct MoodStats {
    let todayMood: Int?
    let sevenDayAverageMood: Double?
    let moodTrend: String
    let bestMoodDay: String?
}

struct AppStats {
    let generatedAt: String
    let dayOfWeek: String
    let globalLevel: Int
    let globalXP: Int
    let categoryStats: [CategoryStats]
    let dietStats: DietStats
    let exerciseStats: ExerciseStats
    let sleepStats: SleepStats
    let weightStats: WeightStats
    let moodStats: MoodStats
    let latestJournalEntry: String?
    let journalDate: String?
}

// MARK: - Service

struct GoalStatsService {

    static func computeAppStats(in context: ModelContext) -> AppStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let players = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        let player = players.first

        let categories = (try? context.fetch(FetchDescriptor<CategoryLevel>())) ?? []
        let categoryStats = categories.map { computeCategoryStats($0, calendar: calendar, today: today, context: context) }

        let dietStats = computeDietStats(context: context, calendar: calendar, today: today)
        let exerciseStats = computeExerciseStats(context: context, calendar: calendar, today: today)
        let sleepStats = computeSleepStats(context: context, calendar: calendar, today: today)
        let weightStats = computeWeightStats(context: context, calendar: calendar, today: today)
        let moodStats = computeMoodStats(context: context, calendar: calendar, today: today)

        var journalDescriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        journalDescriptor.fetchLimit = 1
        let latestJournal = (try? context.fetch(journalDescriptor))?.first

        let generatedAt = Date().formatted(.dateTime.month().day().year().hour().minute())
        let dayOfWeek = today.formatted(.dateTime.weekday(.wide))

        return AppStats(
            generatedAt: generatedAt,
            dayOfWeek: dayOfWeek,
            globalLevel: player?.globalLevel ?? 1,
            globalXP: player?.globalXP ?? 0,
            categoryStats: categoryStats,
            dietStats: dietStats,
            exerciseStats: exerciseStats,
            sleepStats: sleepStats,
            weightStats: weightStats,
            moodStats: moodStats,
            latestJournalEntry: latestJournal?.body,
            journalDate: latestJournal.map { $0.date.formatted(.dateTime.month().day().year()) }
        )
    }

    // MARK: - Category & Goal Stats

    private static func computeCategoryStats(
        _ category: CategoryLevel,
        calendar: Calendar,
        today: Date,
        context: ModelContext
    ) -> CategoryStats {
        let streak = DashboardService.streak(for: category, in: context)
        let goalStats = category.goals
            .filter(\.isActive)
            .sorted { $0.createdDate < $1.createdDate }
            .map { computeGoalStats($0, category: category, calendar: calendar, today: today) }

        return CategoryStats(
            categoryName: category.name,
            level: category.level,
            xp: category.xp,
            currentStreak: streak,
            goalStats: goalStats
        )
    }

    private static func computeGoalStats(
        _ goal: Goal,
        category: CategoryLevel,
        calendar: Calendar,
        today: Date
    ) -> GoalStats {
        let loggedDays = allLoggedDays(for: goal, calendar: calendar)
        let streak = currentStreak(from: loggedDays, today: today, calendar: calendar)
        let longest = longestStreak(from: loggedDays, calendar: calendar)

        let daysActive = max(0, (calendar.dateComponents([.day], from: calendar.startOfDay(for: goal.createdDate), to: today).day ?? 0) + 1)
        let daysRemaining: Int? = goal.targetDate.map {
            calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: $0)).day ?? 0
        }
        let targetDateString = goal.targetDate.map {
            $0.formatted(.dateTime.month(.abbreviated).day().year())
        } ?? "No target date"

        let subMetricStats = goal.subMetrics.map {
            computeSubMetricStats($0, calendar: calendar, today: today)
        }

        let weekdayPerf = weekdayPerformance(for: goal, loggedDays: loggedDays, calendar: calendar, today: today)
        let (velCurrent, velPrevious) = weeklyVelocity(for: goal, calendar: calendar, today: today)
        let velTrend = velocityTrend(current: velCurrent, previous: velPrevious)

        return GoalStats(
            goalName: goal.name,
            category: category.name,
            frequency: goal.frequency,
            xpValue: goal.xpValue,
            currentStreak: streak,
            longestStreak: longest,
            targetDate: targetDateString,
            daysActive: daysActive,
            daysRemaining: daysRemaining,
            subMetricStats: subMetricStats,
            weekdayPerformance: weekdayPerf,
            velocityCurrentWeek: velCurrent,
            velocityPreviousWeek: velPrevious,
            velocityTrend: velTrend
        )
    }

    private static func computeSubMetricStats(
        _ metric: SubMetric,
        calendar: Calendar,
        today: Date
    ) -> SubMetricStats {
        let sortedLogs = metric.logs.sorted { $0.date < $1.date }

        func sumForDay(_ daysAgo: Int) -> Double? {
            guard let targetDay = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let entries = sortedLogs.filter { calendar.startOfDay(for: $0.date) == targetDay }
            return entries.isEmpty ? nil : entries.reduce(0.0) { $0 + $1.value }
        }

        let todayVal = sumForDay(0)
        let yday = sumForDay(1)
        let d2 = sumForDay(2)
        let d3 = sumForDay(3)
        let d4 = sumForDay(4)
        let d5 = sumForDay(5)

        let sevenDayVals = (0..<7).compactMap { sumForDay($0) }
        let sevenAvg: Double? = sevenDayVals.isEmpty ? nil : sevenDayVals.reduce(0, +) / Double(sevenDayVals.count)

        let thirtyDayVals = (0..<30).compactMap { sumForDay($0) }
        let thirtyAvg: Double? = thirtyDayVals.isEmpty ? nil : thirtyDayVals.reduce(0, +) / Double(thirtyDayVals.count)

        let best = sortedLogs.map(\.value).max()

        let recent = [todayVal, yday, d2].compactMap { $0 }
        let prev = [d3, d4, d5].compactMap { $0 }
        let trend = trendString(recentValues: recent, previousValues: prev)

        return SubMetricStats(
            name: metric.name,
            unit: metric.unit,
            targetValue: metric.targetValue,
            type: metric.type,
            today: todayVal,
            yesterday: yday,
            twoDaysAgo: d2,
            threeDaysAgo: d3,
            fourDaysAgo: d4,
            sevenDayAverage: sevenAvg,
            thirtyDayAverage: thirtyAvg,
            bestValue: best,
            trend: trend
        )
    }

    // MARK: - Diet Stats

    private static func computeDietStats(context: ModelContext, calendar: Calendar, today: Date) -> DietStats {
        var descriptor = FetchDescriptor<FoodLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let cutoff = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        descriptor.predicate = #Predicate { $0.date >= cutoff }
        descriptor.fetchLimit = 500
        let logs = (try? context.fetch(descriptor)) ?? []

        func sumCalories(_ daysAgo: Int) -> Double? {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let entries = logs.filter { calendar.startOfDay(for: $0.date) == day }
            return entries.isEmpty ? nil : entries.reduce(0.0) { $0 + $1.calories }
        }
        func sumProtein(_ daysAgo: Int) -> Double? {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let entries = logs.filter { calendar.startOfDay(for: $0.date) == day }
            return entries.isEmpty ? nil : entries.reduce(0.0) { $0 + $1.protein }
        }

        let calToday = sumCalories(0)
        let calYday = sumCalories(1)
        let cal2 = sumCalories(2)
        let cal3 = sumCalories(3)
        let cal4 = sumCalories(4)
        let cal5 = sumCalories(5)

        let cal7Vals = (0..<7).compactMap { sumCalories($0) }
        let cal7Avg: Double? = cal7Vals.isEmpty ? nil : cal7Vals.reduce(0, +) / Double(cal7Vals.count)
        let cal30Vals = (0..<30).compactMap { sumCalories($0) }
        let cal30Avg: Double? = cal30Vals.isEmpty ? nil : cal30Vals.reduce(0, +) / Double(cal30Vals.count)

        let protToday = sumProtein(0)
        let protYday = sumProtein(1)
        let prot2 = sumProtein(2)
        let prot3 = sumProtein(3)
        let prot4 = sumProtein(4)
        let prot5 = sumProtein(5)

        let prot7Vals = (0..<7).compactMap { sumProtein($0) }
        let prot7Avg: Double? = prot7Vals.isEmpty ? nil : prot7Vals.reduce(0, +) / Double(prot7Vals.count)
        let prot30Vals = (0..<30).compactMap { sumProtein($0) }
        let prot30Avg: Double? = prot30Vals.isEmpty ? nil : prot30Vals.reduce(0, +) / Double(prot30Vals.count)

        let calTrend = trendString(
            recentValues: [calToday, calYday, cal2].compactMap { $0 },
            previousValues: [cal3, cal4, cal5].compactMap { $0 }
        )
        let protTrend = trendString(
            recentValues: [protToday, protYday, prot2].compactMap { $0 },
            previousValues: [prot3, prot4, prot5].compactMap { $0 }
        )

        return DietStats(
            todayCalories: calToday, yesterdayCalories: calYday,
            twoDaysAgoCalories: cal2, threeDaysAgoCalories: cal3, fourDaysAgoCalories: cal4,
            sevenDayAverageCalories: cal7Avg, thirtyDayAverageCalories: cal30Avg,
            todayProtein: protToday, yesterdayProtein: protYday,
            twoDaysAgoProtein: prot2, threeDaysAgoProtein: prot3, fourDaysAgoProtein: prot4,
            sevenDayAverageProtein: prot7Avg, thirtyDayAverageProtein: prot30Avg,
            calorieTrend: calTrend, proteinTrend: protTrend
        )
    }

    // MARK: - Exercise Stats

    private static func computeExerciseStats(context: ModelContext, calendar: Calendar, today: Date) -> ExerciseStats {
        let cutoff = calendar.date(byAdding: .day, value: -60, to: today) ?? today

        var liftDesc = FetchDescriptor<LiftingEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        liftDesc.predicate = #Predicate { $0.date >= cutoff }
        let liftings = (try? context.fetch(liftDesc)) ?? []

        var cardioDesc = FetchDescriptor<CardioEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        cardioDesc.predicate = #Predicate { $0.date >= cutoff }
        let cardios = (try? context.fetch(cardioDesc)) ?? []

        let weekComps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let weekStart = calendar.date(from: weekComps) ?? today
        let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? today

        let liftDaysThis = Set(liftings.filter { $0.date >= weekStart && $0.date <= today }
            .map { calendar.startOfDay(for: $0.date) }).count
        let liftDaysLast = Set(liftings.filter { $0.date >= prevWeekStart && $0.date < weekStart }
            .map { calendar.startOfDay(for: $0.date) }).count
        let cardioDaysThis = Set(cardios.filter { $0.date >= weekStart && $0.date <= today }
            .map { calendar.startOfDay(for: $0.date) }).count
        let cardioDaysLast = Set(cardios.filter { $0.date >= prevWeekStart && $0.date < weekStart }
            .map { calendar.startOfDay(for: $0.date) }).count

        let liftDaySet = Set(liftings.map { calendar.startOfDay(for: $0.date) })
        let cardioDaySet = Set(cardios.map { calendar.startOfDay(for: $0.date) })
        let liftStreak = currentStreak(from: liftDaySet, today: today, calendar: calendar)
        let cardioStreak = currentStreak(from: cardioDaySet, today: today, calendar: calendar)

        let thisWeekSets = liftings.filter { $0.date >= weekStart }.reduce(0) { $0 + $1.sets.count }
        let thisWeekCardioMin = cardios.filter { $0.date >= weekStart }.reduce(0.0) { $0 + $1.durationMinutes }

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        var recentPRs: [String] = []
        let byExercise = Dictionary(grouping: liftings, by: \.exerciseName)
        for (name, entries) in byExercise {
            let recent = entries.filter { calendar.startOfDay(for: $0.date) >= sevenDaysAgo }
            let older = entries.filter { calendar.startOfDay(for: $0.date) < sevenDaysAgo }
            let recentMax = recent.flatMap(\.sets).map(\.weightKg).max() ?? 0
            let olderMax = older.flatMap(\.sets).map(\.weightKg).max() ?? 0
            if recentMax > olderMax && recentMax > 0 {
                recentPRs.append("\(name): \(String(format: "%.1f", recentMax)) lbs")
            }
        }

        return ExerciseStats(
            liftingDaysThisWeek: liftDaysThis,
            liftingDaysLastWeek: liftDaysLast,
            cardioDaysThisWeek: cardioDaysThis,
            cardioDaysLastWeek: cardioDaysLast,
            currentLiftingStreak: liftStreak,
            currentCardioStreak: cardioStreak,
            recentPRs: recentPRs,
            totalSetsThisWeek: thisWeekSets,
            totalCardioMinutesThisWeek: thisWeekCardioMin
        )
    }

    // MARK: - Sleep Stats

    private static func computeSleepStats(context: ModelContext, calendar: Calendar, today: Date) -> SleepStats {
        var descriptor = FetchDescriptor<SleepLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let cutoff = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        descriptor.predicate = #Predicate { $0.date >= cutoff }
        descriptor.fetchLimit = 100
        let logs = (try? context.fetch(descriptor)) ?? []

        func sleepFor(_ daysAgo: Int) -> Double? {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            return logs.first { calendar.startOfDay(for: $0.date) == day }?.hoursSlept
        }

        let n0 = sleepFor(1) // last night
        let n1 = sleepFor(2)
        let n2 = sleepFor(3)
        let n3 = sleepFor(4)
        let n4 = sleepFor(5)

        let seven = (1...7).compactMap { sleepFor($0) }
        let sevenAvg: Double? = seven.isEmpty ? nil : seven.reduce(0, +) / Double(seven.count)
        let thirty = (1...30).compactMap { sleepFor($0) }
        let thirtyAvg: Double? = thirty.isEmpty ? nil : thirty.reduce(0, +) / Double(thirty.count)

        let trend = trendString(
            recentValues: [n0, n1, n2].compactMap { $0 },
            previousValues: [n2, n3, n4].compactMap { $0 }
        )

        return SleepStats(
            lastNight: n0, twoDaysAgo: n1, threeDaysAgo: n2,
            fourDaysAgo: n3, fiveDaysAgo: n4,
            sevenDayAverage: sevenAvg, thirtyDayAverage: thirtyAvg,
            trend: trend, goalHours: 8.0
        )
    }

    // MARK: - Weight Stats

    private static func computeWeightStats(context: ModelContext, calendar: Calendar, today: Date) -> WeightStats {
        var descriptor = FetchDescriptor<WeightLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let cutoff = calendar.date(byAdding: .day, value: -31, to: today) ?? today
        descriptor.predicate = #Predicate { $0.date >= cutoff }
        descriptor.fetchLimit = 100
        let logs = (try? context.fetch(descriptor)) ?? []

        let current = logs.first?.weightLbs
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today

        let w7 = logs.filter { calendar.startOfDay(for: $0.date) <= sevenDaysAgo }.first?.weightLbs
        let w30 = logs.filter { calendar.startOfDay(for: $0.date) <= thirtyDaysAgo }.first?.weightLbs

        let trend: String
        if let c = current, let w = w7 {
            let delta = c - w
            if delta > 0.5 { trend = "increasing" }
            else if delta < -0.5 { trend = "decreasing" }
            else { trend = "stable" }
        } else {
            trend = "stable"
        }

        let weeklyRate: Double? = (current != nil && w7 != nil) ? ((current! - w7!) / 7 * 7) : nil

        return WeightStats(
            current: current,
            sevenDaysAgo: w7,
            thirtyDaysAgo: w30,
            trend: trend,
            weeklyChangeRate: weeklyRate
        )
    }

    // MARK: - Mood Stats

    private static func computeMoodStats(context: ModelContext, calendar: Calendar, today: Date) -> MoodStats {
        var descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let cutoff = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        descriptor.predicate = #Predicate { $0.date >= cutoff }
        descriptor.fetchLimit = 50
        let entries = (try? context.fetch(descriptor)) ?? []

        let todayMood = entries.first { calendar.isDateInToday($0.date) }.map { $0.mood }

        let sevenDayCutoff = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let recentMoods = entries.filter { $0.date >= sevenDayCutoff && $0.mood > 0 }.map { Double($0.mood) }
        let sevenAvg: Double? = recentMoods.isEmpty ? nil : recentMoods.reduce(0, +) / Double(recentMoods.count)

        let olderMoods = entries.filter { $0.date < sevenDayCutoff && $0.mood > 0 }.prefix(3).map { Double($0.mood) }
        let moodTrend = trendString(
            recentValues: recentMoods.prefix(3).map { $0 },
            previousValues: Array(olderMoods)
        )

        // Best mood day: weekday with highest average mood
        var weekdayMoods = [Int: [Double]]()
        for entry in entries where entry.mood > 0 {
            let wd = calendar.component(.weekday, from: entry.date)
            weekdayMoods[wd, default: []].append(Double(entry.mood))
        }
        let weekdayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let bestDay: String? = weekdayMoods
            .mapValues { $0.reduce(0, +) / Double($0.count) }
            .max(by: { $0.value < $1.value })
            .map { weekdayNames[safe: $0.key] ?? "Unknown" }

        return MoodStats(
            todayMood: todayMood,
            sevenDayAverageMood: sevenAvg,
            moodTrend: moodTrend,
            bestMoodDay: bestDay
        )
    }

    // MARK: - Helpers

    private static func allLoggedDays(for goal: Goal, calendar: Calendar) -> Set<Date> {
        var days = Set<Date>()
        for metric in goal.subMetrics {
            for log in metric.logs {
                days.insert(calendar.startOfDay(for: log.date))
            }
        }
        return days
    }

    private static func currentStreak(from days: Set<Date>, today: Date, calendar: Calendar) -> Int {
        var streak = 0
        var checkDate = today
        while days.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    private static func longestStreak(from days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                if current > longest { longest = current }
            } else {
                current = 1
            }
        }
        return longest
    }

    private static func weekdayPerformance(
        for goal: Goal,
        loggedDays: Set<Date>,
        calendar: Calendar,
        today: Date
    ) -> [String: Double] {
        let startDay = calendar.startOfDay(for: goal.createdDate)
        let totalDays = max(0, (calendar.dateComponents([.day], from: startDay, to: today).day ?? 0) + 1)
        let weekdayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        var counts = [Int: (logged: Int, total: Int)]()
        for i in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: i, to: startDay) else { continue }
            let wd = calendar.component(.weekday, from: day)
            let logged = loggedDays.contains(day) ? 1 : 0
            counts[wd] = ((counts[wd]?.logged ?? 0) + logged, (counts[wd]?.total ?? 0) + 1)
        }

        var result = [String: Double]()
        for (wd, data) in counts {
            let name = weekdayNames[safe: wd] ?? "Unknown"
            result[name] = data.total > 0 ? Double(data.logged) / Double(data.total) : 0
        }
        return result
    }

    private static func weeklyVelocity(for goal: Goal, calendar: Calendar, today: Date) -> (Double, Double) {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let weekStart = calendar.date(from: comps) ?? today
        let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? today

        var current = 0.0
        var previous = 0.0
        for metric in goal.subMetrics {
            for log in metric.logs {
                let logDay = calendar.startOfDay(for: log.date)
                if logDay >= weekStart && logDay <= today {
                    current += log.value
                } else if logDay >= prevWeekStart && logDay < weekStart {
                    previous += log.value
                }
            }
        }
        return (current, previous)
    }

    private static func velocityTrend(current: Double, previous: Double) -> String {
        guard previous > 0 else { return current > 0 ? "accelerating" : "steady" }
        let ratio = current / previous
        if ratio > 1.05 { return "accelerating" }
        if ratio < 0.95 { return "decelerating" }
        return "steady"
    }

    private static func trendString(recentValues: [Double], previousValues: [Double]) -> String {
        guard !recentValues.isEmpty, !previousValues.isEmpty else { return "stable" }
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let prevAvg = previousValues.reduce(0, +) / Double(previousValues.count)
        guard prevAvg > 0 else { return recentAvg > 0 ? "improving" : "stable" }
        let change = (recentAvg - prevAvg) / prevAvg
        if change > 0.05 { return "improving" }
        if change < -0.05 { return "declining" }
        return "stable"
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
