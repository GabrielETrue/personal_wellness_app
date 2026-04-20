import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CategoryLevel.name) private var categories: [CategoryLevel]

    @State private var numericInputs: [UUID: String] = [:]
    @State private var checkedItems: Set<UUID> = []

    private let categoryOrder = ["Diet", "Exercise", "Sleep", "Custom"]

    private var sortedCategoriesWithGoals: [CategoryLevel] {
        categories
            .filter { !$0.goals.filter(\.isActive).isEmpty }
            .sorted {
                (categoryOrder.firstIndex(of: $0.name) ?? 99) <
                (categoryOrder.firstIndex(of: $1.name) ?? 99)
            }
    }

    private var hasAnyInput: Bool {
        numericInputs.values.contains { !$0.isEmpty } || !checkedItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                if sortedCategoriesWithGoals.isEmpty {
                    ContentUnavailableView(
                        "No Active Goals",
                        systemImage: "target",
                        description: Text("Add goals in the Goals tab to start logging.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(sortedCategoriesWithGoals) { category in
                                CategoryQuickSection(
                                    category: category,
                                    numericInputs: $numericInputs,
                                    checkedItems: $checkedItems,
                                    onLogGoal: { logGoal($0, category: category) }
                                )
                            }

                            GradientSaveButton(title: "Log All", isEnabled: hasAnyInput) {
                                logAll()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Log Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear { populateChecklistState() }
        }
    }

    private func populateChecklistState() {
        let calendar = Calendar.current
        for category in categories {
            for goal in category.goals where goal.isActive {
                for metric in goal.subMetrics where metric.isChecklistItem {
                    if metric.logs.contains(where: { calendar.isDateInToday($0.date) }) {
                        checkedItems.insert(metric.id)
                    }
                }
            }
        }
    }

    private func logGoal(_ goal: Goal, category: CategoryLevel) {
        let created = createEntries(for: goal)
        if created { awardXP(for: goal, in: category) }
        do {
            try modelContext.save()
        } catch {
            print("QuickLogView logGoal save failed: \(error)")
        }
    }

    private func logAll() {
        for category in sortedCategoriesWithGoals {
            for goal in category.goals where goal.isActive {
                let created = createEntries(for: goal)
                if created { awardXP(for: goal, in: category) }
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("QuickLogView logAll save failed: \(error)")
        }
        dismiss()
    }

    @discardableResult
    private func createEntries(for goal: Goal) -> Bool {
        var createdAny = false
        for metric in goal.subMetrics {
            if metric.isChecklistItem {
                let alreadyLogged = metric.logs.contains { Calendar.current.isDateInToday($0.date) }
                if checkedItems.contains(metric.id) && !alreadyLogged {
                    let entry = LogEntry(value: 1.0, date: Date(), notes: "")
                    modelContext.insert(entry)
                    entry.subMetric = metric
                    createdAny = true
                }
            } else {
                if let text = numericInputs[metric.id],
                   !text.isEmpty,
                   let val = Double(text) {
                    let entry = LogEntry(value: val, date: Date(), notes: "")
                    modelContext.insert(entry)
                    entry.subMetric = metric
                    createdAny = true
                }
            }
        }
        return createdAny
    }

    private func awardXP(for goal: Goal, in category: CategoryLevel) {
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
}

// MARK: - Category Section

private struct CategoryQuickSection: View {
    let category: CategoryLevel
    @Binding var numericInputs: [UUID: String]
    @Binding var checkedItems: Set<UUID>
    let onLogGoal: (Goal) -> Void

    private var activeGoals: [Goal] {
        category.goals.filter(\.isActive).sorted { $0.createdDate < $1.createdDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .foregroundStyle(AppTheme.accentBlue)
                Text(category.name.uppercased())
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accentBlue)
                    .kerning(1.2)
            }

            ForEach(activeGoals) { goal in
                GoalQuickCard(
                    goal: goal,
                    numericInputs: $numericInputs,
                    checkedItems: $checkedItems,
                    onLog: { onLogGoal(goal) }
                )
            }
        }
    }
}

// MARK: - Goal Card

private struct GoalQuickCard: View {
    let goal: Goal
    @Binding var numericInputs: [UUID: String]
    @Binding var checkedItems: Set<UUID>
    let onLog: () -> Void

    private var hasLoggedToday: Bool {
        goal.subMetrics.contains { m in
            m.logs.contains { Calendar.current.isDateInToday($0.date) }
        }
    }

    private var hasInput: Bool {
        goal.subMetrics.contains { m in
            if m.isChecklistItem { return checkedItems.contains(m.id) }
            return !(numericInputs[m.id] ?? "").isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    if hasLoggedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
                            .font(.subheadline)
                    }
                    Text(goal.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Text("\(goal.xpValue) XP")
                    .font(.caption2).fontWeight(.semibold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(AppTheme.accentBlue.opacity(0.18))
                    .foregroundStyle(AppTheme.accentBlue)
                    .clipShape(Capsule())
            }

            ForEach(goal.subMetrics) { metric in
                if metric.isChecklistItem {
                    ChecklistMetricInputRow(metric: metric, checkedItems: $checkedItems)
                } else {
                    NumericMetricInputRow(metric: metric, numericInputs: $numericInputs)
                }
            }

            HStack {
                Spacer()
                Button("Log") { onLog() }
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(hasInput ? AppTheme.accentBlue : AppTheme.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(hasInput ? AppTheme.accentBlue : AppTheme.textSecondary.opacity(0.4), lineWidth: 1)
                    )
                    .disabled(!hasInput)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentBlue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Metric Input Rows

private struct NumericMetricInputRow: View {
    let metric: SubMetric
    @Binding var numericInputs: [UUID: String]

    private var todayTotal: Double {
        metric.logs
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progress: Double {
        metric.targetValue > 0 ? min(todayTotal / metric.targetValue, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.name)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                if !metric.unit.isEmpty {
                    Text("(\(metric.unit))")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                TextField("0", text: Binding(
                    get: { numericInputs[metric.id] ?? "" },
                    set: { numericInputs[metric.id] = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.textPrimary)
                .tint(AppTheme.accentBlue)
                .frame(maxWidth: 70)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(AppTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if metric.targetValue > 0 {
                GradientProgressBar(value: progress, height: 4)
                Text("\(todayTotal.formatted()) / \(metric.targetValue.formatted()) \(metric.unit) today")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

private struct ChecklistMetricInputRow: View {
    let metric: SubMetric
    @Binding var checkedItems: Set<UUID>

    var body: some View {
        Toggle(metric.name, isOn: Binding(
            get: { checkedItems.contains(metric.id) },
            set: { on in
                if on { checkedItems.insert(metric.id) } else { checkedItems.remove(metric.id) }
            }
        ))
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
        .tint(AppTheme.accentBlue)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: PlayerProfile.self, CategoryLevel.self, LevelEvent.self,
            Goal.self, SubMetric.self, LogEntry.self,
        configurations: config
    )
    let ctx = container.mainContext
    let player = PlayerProfile()
    ctx.insert(player)
    let cat = CategoryLevel(name: "Diet", icon: "fork.knife")
    ctx.insert(cat)
    cat.player = player
    let goal = Goal(name: "Daily Nutrition", frequency: "daily", xpValue: 20)
    ctx.insert(goal)
    goal.category = cat
    let cal = SubMetric(name: "Calories", unit: "kcal", targetValue: 2000)
    ctx.insert(cal)
    cal.goal = goal
    let stretch = SubMetric(name: "Stretch", unit: "", targetValue: 1, type: "checklist")
    ctx.insert(stretch)
    stretch.goal = goal
    return QuickLogView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
