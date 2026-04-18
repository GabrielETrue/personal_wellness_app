import SwiftUI
import SwiftData

struct LogProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var selectedSubMetric: SubMetric?
    @State private var value = ""
    @State private var notes = ""
    @State private var date = Date()

    private var canSave: Bool {
        selectedSubMetric != nil && Double(value) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Sub-Metric") {
                            Picker("Log for", selection: $selectedSubMetric) {
                                Text("Select…").tag(nil as SubMetric?)
                                ForEach(goal.subMetrics) { metric in
                                    Text("\(metric.name) (\(metric.unit))").tag(metric as SubMetric?)
                                }
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                        }

                        FormCard(header: "Entry") {
                            ThemedTextField("Value", text: $value)
                                .keyboardType(.decimalPad)
                            Divider().background(AppTheme.backgroundSecondary)
                            ThemedTextField("Notes (optional)", text: $notes)
                            Divider().background(AppTheme.backgroundSecondary)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Entry", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear {
                selectedSubMetric = goal.subMetrics.first
            }
        }
    }

    private func save() {
        guard let metric = selectedSubMetric, let numericValue = Double(value) else { return }

        let entry = LogEntry(value: numericValue, date: date, notes: notes)
        modelContext.insert(entry)
        entry.subMetric = metric

        awardXP()
        try? modelContext.save()
        dismiss()
    }

    private func awardXP() {
        guard let category = goal.category else { return }

        category.xp += goal.xpValue
        levelUp(category: category)

        if let player = category.player {
            player.globalXP += goal.xpValue
            globalLevelUp(player: player)
        }
    }

    private func levelUp(category: CategoryLevel) {
        while category.xp >= 100 * category.level {
            category.xp -= 100 * category.level
            category.level += 1
            let event = LevelEvent(level: category.level)
            modelContext.insert(event)
            event.categoryLevel = category
        }
    }

    private func globalLevelUp(player: PlayerProfile) {
        while player.globalXP >= 100 * player.globalLevel {
            player.globalXP -= 100 * player.globalLevel
            player.globalLevel += 1
        }
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
    container.mainContext.insert(player)
    container.mainContext.insert(cat)
    container.mainContext.insert(goal)
    container.mainContext.insert(metric)
    return LogProgressView(goal: goal)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
