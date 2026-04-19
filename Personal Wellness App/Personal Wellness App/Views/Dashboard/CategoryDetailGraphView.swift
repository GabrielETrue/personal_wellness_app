import SwiftUI
import SwiftData
import Charts

struct CategoryDetailGraphView: View {
    let category: CategoryLevel
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var selectedHorizon: TimeHorizon = .month

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .foregroundStyle(AppTheme.accentBlue)
                    .shadow(color: AppTheme.accentBlue.opacity(0.6), radius: 4)
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Lv \(category.level)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(AppTheme.accentPurple.opacity(0.2))
                    .foregroundStyle(AppTheme.accentPurple)
                    .clipShape(Capsule())
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Horizon Picker
            HorizonPicker(selected: $selectedHorizon)

            // Category-specific charts
            switch category.name {
            case "Diet":
                DietChartsSection(context: modelContext, horizon: selectedHorizon)
            case "Exercise":
                ExerciseChartsSection(context: modelContext, horizon: selectedHorizon)
            case "Sleep":
                SleepChartsSection(context: modelContext, horizon: selectedHorizon)
            default:
                CustomCategoryChartsSection(category: category, horizon: selectedHorizon)
            }

            // Weight chart — all categories
            WeightChartSection(context: modelContext, horizon: selectedHorizon)

            // Active Goals
            ActiveGoalsSection(category: category)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accentPurple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Horizon Picker

private struct HorizonPicker: View {
    @Binding var selected: TimeHorizon

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeHorizon.allCases, id: \.self) { horizon in
                    Button {
                        selected = horizon
                    } label: {
                        Text(horizon.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selected == horizon
                                          ? AppTheme.accentBlue
                                          : AppTheme.backgroundSecondary)
                            )
                            .foregroundStyle(selected == horizon
                                             ? AppTheme.textPrimary
                                             : AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Chart Card Container

private struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.accentBlue)
                .kerning(1.0)
            content()
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppTheme.textSecondary.opacity(0.2))
                        AxisValueLabel().foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(AppTheme.textSecondary.opacity(0.2))
                        AxisValueLabel().foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accentBlue.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
}

private func emptyChartPlaceholder(_ label: String) -> some View {
    Text(label)
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 80)
        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.backgroundSecondary))
}

// MARK: - Diet Charts

private struct DietChartsSection: View {
    let context: ModelContext
    let horizon: TimeHorizon

    var body: some View {
        let calories = DashboardService.dailyCalories(horizon: horizon, in: context)
        let protein = DashboardService.dailyProtein(horizon: horizon, in: context)

        ChartCard(title: "Calories (\(horizon.rawValue))") {
            if calories.allSatisfy({ $0.value == 0 }) {
                emptyChartPlaceholder("No food logged yet")
            } else if horizon == .week {
                Chart(calories) { item in
                    BarMark(x: .value("Day", item.label), y: .value("kcal", item.value))
                        .foregroundStyle(AppTheme.accentBlue)
                        .cornerRadius(4)
                }
            } else {
                let filtered = calories.filter { $0.value > 0 }
                Chart(filtered) { item in
                    LineMark(x: .value("Date", item.date), y: .value("kcal", item.value))
                        .foregroundStyle(AppTheme.accentBlue)
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", item.date), y: .value("kcal", item.value))
                        .foregroundStyle(AppTheme.accentBlue.opacity(0.1))
                        .interpolationMethod(.monotone)
                }
            }
        }

        ChartCard(title: "Protein (\(horizon.rawValue))") {
            if protein.allSatisfy({ $0.value == 0 }) {
                emptyChartPlaceholder("No food logged yet")
            } else if horizon == .week {
                Chart(protein) { item in
                    BarMark(x: .value("Day", item.label), y: .value("g", item.value))
                        .foregroundStyle(AppTheme.accentPurple)
                        .cornerRadius(4)
                }
            } else {
                let filtered = protein.filter { $0.value > 0 }
                Chart(filtered) { item in
                    LineMark(x: .value("Date", item.date), y: .value("g", item.value))
                        .foregroundStyle(AppTheme.accentPurple)
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", item.date), y: .value("g", item.value))
                        .foregroundStyle(AppTheme.accentPurple.opacity(0.1))
                        .interpolationMethod(.monotone)
                }
            }
        }
    }
}

// MARK: - Exercise Charts

private struct ExerciseChartsSection: View {
    let context: ModelContext
    let horizon: TimeHorizon
    private let accentColors: [Color] = [AppTheme.accentBlue, AppTheme.accentPurple, AppTheme.accentCyan, AppTheme.warning]

    var body: some View {
        let lifting = DashboardService.liftingDaysPerWeek(horizon: horizon, in: context)
        let cardio = DashboardService.cardioDaysPerWeek(horizon: horizon, in: context)
        let progress = DashboardService.exerciseProgress(horizon: horizon, in: context)

        ChartCard(title: "Lifting Days/Week (\(horizon.rawValue))") {
            Chart(lifting) { item in
                BarMark(x: .value("Week", item.weekLabel), y: .value("Days", item.value))
                    .foregroundStyle(AppTheme.accentBlue)
                    .cornerRadius(4)
            }
            .chartYScale(domain: 0...7)
        }

        ChartCard(title: "Cardio Days/Week (\(horizon.rawValue))") {
            Chart(cardio) { item in
                BarMark(x: .value("Week", item.weekLabel), y: .value("Days", item.value))
                    .foregroundStyle(AppTheme.accentPurple)
                    .cornerRadius(4)
            }
            .chartYScale(domain: 0...7)
        }

        if !progress.isEmpty {
            let grouped = Dictionary(grouping: progress, by: \.exerciseName)
            let sortedNames = grouped.keys.sorted()

            ChartCard(title: "Max Weight Over Time (\(horizon.rawValue))") {
                Chart {
                    ForEach(Array(sortedNames.enumerated()), id: \.element) { i, name in
                        ForEach(grouped[name] ?? []) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("kg", point.maxWeight)
                            )
                            .foregroundStyle(accentColors[i % accentColors.count])
                            .interpolationMethod(.monotone)
                            .symbol(Circle())
                            .symbolSize(30)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                ForEach(Array(sortedNames.prefix(4).enumerated()), id: \.element) { i, name in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accentColors[i % accentColors.count])
                            .frame(width: 7, height: 7)
                        Text(name)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - Sleep Charts

private struct SleepChartsSection: View {
    let context: ModelContext
    let horizon: TimeHorizon

    private func sleepColor(_ hours: Double) -> Color {
        if hours >= 8 { return AppTheme.success }
        if hours >= 6 { return AppTheme.warning }
        return AppTheme.danger
    }

    var body: some View {
        let data = DashboardService.sleepPerNight(horizon: horizon, in: context)

        ChartCard(title: "Hours Slept (\(horizon.rawValue))") {
            if horizon == .week {
                Chart(data) { item in
                    BarMark(x: .value("Day", item.label), y: .value("Hours", item.value))
                        .foregroundStyle(sleepColor(item.value))
                        .cornerRadius(4)
                    RuleMark(y: .value("Goal", 8.0))
                        .foregroundStyle(AppTheme.accentCyan.opacity(0.6))
                        .lineStyle(StrokeStyle(dash: [4, 4]))
                }
                .chartYScale(domain: 0...10)
            } else {
                let filtered = data.filter { $0.value > 0 }
                if filtered.isEmpty {
                    emptyChartPlaceholder("No data yet")
                } else {
                    Chart(filtered) { item in
                        LineMark(x: .value("Date", item.date), y: .value("Hours", item.value))
                            .foregroundStyle(AppTheme.accentCyan)
                            .interpolationMethod(.monotone)
                        AreaMark(x: .value("Date", item.date), y: .value("Hours", item.value))
                            .foregroundStyle(AppTheme.accentCyan.opacity(0.1))
                            .interpolationMethod(.monotone)
                        RuleMark(y: .value("Goal", 8.0))
                            .foregroundStyle(AppTheme.accentCyan.opacity(0.5))
                            .lineStyle(StrokeStyle(dash: [4, 4]))
                    }
                }
            }
        }
    }
}

// MARK: - Custom Category Charts

private struct CustomCategoryChartsSection: View {
    let category: CategoryLevel
    let horizon: TimeHorizon

    var body: some View {
        let activeGoals = category.goals.filter(\.isActive).sorted { $0.createdDate < $1.createdDate }
        ForEach(activeGoals) { goal in
            ForEach(goal.subMetrics) { metric in
                CustomMetricChart(goal: goal, metric: metric, horizon: horizon)
            }
        }
    }
}

private struct CustomMetricChart: View {
    let goal: Goal
    let metric: SubMetric
    let horizon: TimeHorizon

    private var cutoffDate: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let days = horizon.days else { return .distantPast }
        return cal.date(byAdding: .day, value: -(days - 1), to: today) ?? today
    }

    var body: some View {
        if metric.isChecklistItem {
            let days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
                .reversed().map { Calendar.current.startOfDay(for: $0) }
            let data: [(Date, Double)] = days.map { day in
                let completed = metric.logs.contains { Calendar.current.startOfDay(for: $0.date) == day }
                return (day, completed ? 1.0 : 0.0)
            }

            ChartCard(title: "\(goal.name) — \(metric.name)") {
                Chart {
                    ForEach(data, id: \.0) { (day, value) in
                        BarMark(
                            x: .value("Day", day.formatted(.dateTime.weekday(.abbreviated))),
                            y: .value("Done", value)
                        )
                        .foregroundStyle(value > 0 ? AppTheme.success : AppTheme.backgroundCard)
                        .cornerRadius(4)
                    }
                }
                .chartYScale(domain: 0...1)
            }
        } else {
            let points = metric.logs
                .filter { $0.date >= cutoffDate }
                .sorted { $0.date < $1.date }

            ChartCard(title: "\(goal.name) — \(metric.name) (\(metric.unit)) (\(horizon.rawValue))") {
                if points.isEmpty {
                    emptyChartPlaceholder("No entries yet")
                } else {
                    Chart(points) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value(metric.unit, entry.value)
                        )
                        .foregroundStyle(AppTheme.accentBlue)
                        .interpolationMethod(.monotone)
                        .symbol(Circle())
                        .symbolSize(25)
                    }
                }
            }
        }
    }
}

// MARK: - Weight Chart (All Categories)

private struct WeightChartSection: View {
    let context: ModelContext
    let horizon: TimeHorizon

    var body: some View {
        let data = DashboardService.weightOverTime(horizon: horizon, in: context)
        ChartCard(title: "Body Weight (\(horizon.rawValue))") {
            if data.isEmpty {
                emptyChartPlaceholder("No weight logged yet")
            } else {
                let minW = (data.map(\.value).min() ?? 0) - 5
                let maxW = (data.map(\.value).max() ?? 0) + 5
                Chart(data) { item in
                    LineMark(x: .value("Date", item.date), y: .value("lbs", item.value))
                        .foregroundStyle(AppTheme.accentBlue)
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Date", item.date), y: .value("lbs", item.value))
                        .foregroundStyle(AppTheme.accentBlue)
                        .symbolSize(30)
                }
                .chartYScale(domain: minW...maxW)
            }
        }
    }
}

// MARK: - Active Goals Section

private struct ActiveGoalsSection: View {
    let category: CategoryLevel

    private var activeGoals: [Goal] {
        category.goals.filter(\.isActive).sorted { $0.createdDate < $1.createdDate }
    }

    var body: some View {
        if !activeGoals.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Active Goals".uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accentBlue)
                    .kerning(1.0)

                ForEach(activeGoals) { goal in
                    ActiveGoalCard(goal: goal)
                }
            }
        }
    }
}

private struct ActiveGoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(goal.xpValue) XP")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentBlue)
            }
            ForEach(goal.subMetrics) { metric in
                SubMetricDetailRow(metric: metric)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.backgroundSecondary)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.accentBlue.opacity(0.12), lineWidth: 1))
        )
    }
}

private struct SubMetricDetailRow: View {
    let metric: SubMetric

    private var todayTotal: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return metric.logs
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progress: Double {
        metric.targetValue > 0 ? min(todayTotal / metric.targetValue, 1.0) : 0
    }

    private var isCompletedToday: Bool {
        metric.logs.contains { Calendar.current.isDateInToday($0.date) }
    }

    private var weekRate: Int {
        Int(DashboardService.completionRate(for: metric, period: "week") * 100)
    }

    var body: some View {
        if metric.isChecklistItem {
            HStack {
                Text(isCompletedToday ? "✅" : "○")
                    .font(.subheadline)
                Text(metric.name)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(weekRate)% this week")
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(AppTheme.accentPurple.opacity(0.15))
                    .foregroundStyle(AppTheme.accentPurple)
                    .clipShape(Capsule())
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(metric.name)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(weekRate)% this week")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(AppTheme.accentPurple.opacity(0.15))
                        .foregroundStyle(AppTheme.accentPurple)
                        .clipShape(Capsule())
                    Text("\(todayTotal.formatted())/\(metric.targetValue.formatted()) \(metric.unit)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                GradientProgressBar(value: progress, height: 5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: PlayerProfile.self, CategoryLevel.self, LevelEvent.self,
            Goal.self, SubMetric.self, LogEntry.self,
            FoodLog.self, CustomNutrient.self, LiftingEntry.self, LiftingSet.self,
            CardioEntry.self, SleepLog.self, JournalEntry.self, AIInsight.self,
            WeightLog.self,
        configurations: config
    )
    let ctx = container.mainContext
    let cat = CategoryLevel(name: "Diet", icon: "fork.knife", xp: 40, level: 2)
    ctx.insert(cat)
    ctx.insert(FoodLog(name: "Oatmeal", calories: 320, protein: 12))
    ctx.insert(FoodLog(name: "Chicken", calories: 450, protein: 45))
    ctx.insert(WeightLog(weightLbs: 178.5))

    return ScrollView {
        CategoryDetailGraphView(category: cat, onDismiss: {})
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
