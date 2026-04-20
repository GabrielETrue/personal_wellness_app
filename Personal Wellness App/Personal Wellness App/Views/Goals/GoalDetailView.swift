import SwiftUI
import SwiftData

struct GoalDetailView: View {
    let goal: Goal

    @Environment(\.modelContext) private var modelContext
    @State private var showingLogProgress = false

    private var recentLogs: [LogEntry] {
        Array(
            goal.subMetrics
                .flatMap(\.logs)
                .sorted { $0.date > $1.date }
                .prefix(50)
        )
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            List {
                Section {
                    if goal.subMetrics.isEmpty {
                        Text("No sub-metrics")
                            .foregroundStyle(AppTheme.textSecondary)
                            .listRowBackground(AppTheme.backgroundCard)
                    } else {
                        ForEach(goal.subMetrics) { metric in
                            if metric.isChecklistItem {
                                ChecklistMetricRow(metric: metric, goal: goal, onToggle: { toggleChecklistEntry(metric: metric, value: $0) })
                            } else {
                                NumericMetricDetailRow(metric: metric)
                            }
                        }
                    }
                } header: {
                    Text("Sub-Metrics")
                        .foregroundStyle(AppTheme.accentBlue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .kerning(1.1)
                }
                .listRowBackground(AppTheme.backgroundCard)

                Section {
                    if recentLogs.isEmpty {
                        Text("No logs yet")
                            .foregroundStyle(AppTheme.textSecondary)
                            .listRowBackground(AppTheme.backgroundCard)
                    } else {
                        ForEach(recentLogs) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.subMetric?.isChecklistItem == true ? "✅ Completed" : entry.value.formatted())
                                        .foregroundStyle(AppTheme.textPrimary)
                                    if !entry.notes.isEmpty {
                                        Text(entry.notes)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .listRowBackground(AppTheme.backgroundCard)
                        }
                    }
                } header: {
                    Text("Recent Logs")
                        .foregroundStyle(AppTheme.accentBlue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .kerning(1.1)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                let hasNumeric = goal.subMetrics.contains { !$0.isChecklistItem }
                if hasNumeric {
                    Button("Log Progress") { showingLogProgress = true }
                        .foregroundStyle(AppTheme.accentBlue)
                        .disabled(goal.subMetrics.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingLogProgress) {
            LogProgressView(goal: goal)
        }
    }

    private func toggleChecklistEntry(metric: SubMetric, value: Bool) {
        if value {
            let existing = metric.logs.first { Calendar.current.isDateInToday($0.date) }
            guard existing == nil else { return }
            let entry = LogEntry(value: 1.0, date: Date(), notes: "")
            modelContext.insert(entry)
            entry.subMetric = metric
            awardXP()
        } else {
            if let existing = metric.logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
                reverseXP()
                modelContext.delete(existing)
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("GoalDetailView toggleChecklistEntry save failed: \(error)")
        }
    }

    private func awardXP() {
        guard let category = goal.category else { return }
        category.xp += goal.xpValue
        while category.xp >= 100 * category.level {
            category.xp -= 100 * category.level
            category.level += 1
            let event = LevelEvent(level: category.level)
            modelContext.insert(event)
            event.categoryLevel = category
        }
        if let player = category.player {
            player.globalXP += goal.xpValue
            while player.globalXP >= 100 * player.globalLevel {
                player.globalXP -= 100 * player.globalLevel
                player.globalLevel += 1
            }
        }
    }

    private func reverseXP() {
        guard let category = goal.category else { return }
        category.xp = max(0, category.xp - goal.xpValue)
        if let player = category.player {
            player.globalXP = max(0, player.globalXP - goal.xpValue)
        }
    }
}

// MARK: - Checklist Row

private struct ChecklistMetricRow: View {
    let metric: SubMetric
    let goal: Goal
    let onToggle: (Bool) -> Void

    private var isLoggedToday: Bool {
        metric.logs.contains { Calendar.current.isDateInToday($0.date) }
    }

    private var weekRate: Int {
        Int(DashboardService.completionRate(for: metric, period: "week") * 100)
    }

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { isLoggedToday },
                set: { onToggle($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.name)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .tint(AppTheme.accentBlue)

            Spacer()

            Text("\(weekRate)% this week")
                .font(.caption2)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(AppTheme.accentPurple.opacity(0.15))
                .foregroundStyle(AppTheme.accentPurple)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Numeric Row

private struct NumericMetricDetailRow: View {
    let metric: SubMetric

    private var todayTotal: Double {
        metric.logs
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progress: Double {
        metric.targetValue > 0 ? min(todayTotal / metric.targetValue, 1.0) : 0
    }

    private var weekRate: Int {
        Int(DashboardService.completionRate(for: metric, period: "week") * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.name)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Target: \(metric.targetValue.formatted()) \(metric.unit)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(weekRate)% this week")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(AppTheme.accentPurple.opacity(0.15))
                        .foregroundStyle(AppTheme.accentPurple)
                        .clipShape(Capsule())
                    Text("\(todayTotal.formatted()) / \(metric.targetValue.formatted()) today")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            GradientProgressBar(value: progress, height: 5)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: PlayerProfile.self, CategoryLevel.self, LevelEvent.self,
            Goal.self, SubMetric.self, LogEntry.self,
        configurations: config
    )
    let player = PlayerProfile()
    let cat = CategoryLevel(name: "Exercise", icon: "figure.run")
    cat.player = player
    player.categoryLevels.append(cat)
    let goal = Goal(name: "Run 5K", frequency: "daily", xpValue: 20)
    goal.category = cat
    cat.goals.append(goal)
    let metric = SubMetric(name: "Distance", unit: "km", targetValue: 5)
    metric.goal = goal
    goal.subMetrics.append(metric)
    let check = SubMetric(name: "Stretch", unit: "", targetValue: 1, type: "checklist")
    check.goal = goal
    goal.subMetrics.append(check)
    container.mainContext.insert(player)
    container.mainContext.insert(cat)
    container.mainContext.insert(goal)
    container.mainContext.insert(metric)
    container.mainContext.insert(check)
    return NavigationStack {
        GoalDetailView(goal: goal)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
