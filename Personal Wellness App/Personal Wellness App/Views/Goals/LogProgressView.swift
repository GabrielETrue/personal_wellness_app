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
    @State private var checklistToggle = false
    @State private var existingChecklistLog: LogEntry? = nil

    private var isChecklist: Bool { selectedSubMetric?.isChecklistItem ?? false }

    private var canSave: Bool {
        guard let metric = selectedSubMetric else { return false }
        if metric.isChecklistItem {
            return checklistToggle != (existingChecklistLog != nil)
        }
        return Double(value) != nil
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
                                    Text(metric.isChecklistItem ? metric.name : "\(metric.name) (\(metric.unit))")
                                        .tag(metric as SubMetric?)
                                }
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .onChange(of: selectedSubMetric) { _, _ in updateChecklistState() }
                        }

                        if isChecklist {
                            checklistEntryCard
                        } else {
                            numericEntryCard
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
                updateChecklistState()
            }
            .onChange(of: date) { _, _ in updateChecklistState() }
        }
    }

    @ViewBuilder
    private var numericEntryCard: some View {
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
    }

    @ViewBuilder
    private var checklistEntryCard: some View {
        FormCard(header: "Entry") {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $checklistToggle) {
                    HStack(spacing: 8) {
                        Image(systemName: checklistToggle ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checklistToggle ? AppTheme.success : AppTheme.textSecondary)
                        Text(selectedSubMetric?.name ?? "Completed")
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .tint(AppTheme.accentBlue)

                if existingChecklistLog != nil {
                    Text("Already logged — toggling off will delete this entry.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warning)
                }
            }

            Divider().background(AppTheme.backgroundSecondary)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .foregroundStyle(AppTheme.textPrimary)
                .tint(AppTheme.accentBlue)
        }
    }

    private func updateChecklistState() {
        guard let metric = selectedSubMetric, metric.isChecklistItem else {
            existingChecklistLog = nil
            checklistToggle = false
            return
        }
        let targetDay = Calendar.current.startOfDay(for: date)
        existingChecklistLog = metric.logs.first {
            Calendar.current.startOfDay(for: $0.date) == targetDay
        }
        checklistToggle = existingChecklistLog != nil
    }

    private func save() {
        guard let metric = selectedSubMetric else { return }

        if metric.isChecklistItem {
            if checklistToggle && existingChecklistLog == nil {
                let entry = LogEntry(value: 1.0, date: date, notes: "")
                modelContext.insert(entry)
                entry.subMetric = metric
                awardXP()
            } else if !checklistToggle, let existing = existingChecklistLog {
                reverseXP()
                modelContext.delete(existing)
            }
        } else {
            guard let numericValue = Double(value) else { return }
            let entry = LogEntry(value: numericValue, date: date, notes: notes)
            modelContext.insert(entry)
            entry.subMetric = metric
            awardXP()
        }

        do {
            try modelContext.save()
        } catch {
            print("LogProgressView save failed: \(error)")
        }
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

    private func reverseXP() {
        guard let category = goal.category else { return }
        category.xp = max(0, category.xp - goal.xpValue)
        if let player = category.player {
            player.globalXP = max(0, player.globalXP - goal.xpValue)
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
    let checklistMetric = SubMetric(name: "Stretch", type: "checklist")
    checklistMetric.goal = goal
    goal.subMetrics.append(checklistMetric)
    container.mainContext.insert(player)
    container.mainContext.insert(cat)
    container.mainContext.insert(goal)
    container.mainContext.insert(metric)
    container.mainContext.insert(checklistMetric)
    return LogProgressView(goal: goal)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
