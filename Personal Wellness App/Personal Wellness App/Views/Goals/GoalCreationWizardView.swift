import SwiftUI
import SwiftData

// MARK: - Template

enum GoalTemplate: String, Identifiable {
    var id: String { rawValue }

    // Diet
    case calorieTarget  = "Calorie Target"
    case proteinGoal    = "Protein Goal"
    case fullNutrition  = "Full Nutrition"
    case customDiet     = "Custom Diet Goal"
    // Exercise
    case liftingProgram = "Lifting Program"
    case cardioProgram  = "Cardio Program"
    case fullFitness    = "Full Fitness"
    case customExercise = "Custom Exercise Goal"
    // Sleep
    case sleepDuration    = "Sleep Duration"
    case sleepConsistency = "Sleep Consistency"
    case customSleep      = "Custom Sleep Goal"
    // Custom category
    case checklistHabit = "Checklist Habit"
    case numericTarget  = "Numeric Target"
    case mixedGoal      = "Mixed Goal"

    var templateIcon: String {
        switch self {
        case .calorieTarget:  return "flame"
        case .proteinGoal:    return "figure.strengthtraining.traditional"
        case .fullNutrition:  return "fork.knife"
        case .customDiet:     return "slider.horizontal.3"
        case .liftingProgram: return "dumbbell"
        case .cardioProgram:  return "figure.run"
        case .fullFitness:    return "heart.fill"
        case .customExercise: return "slider.horizontal.3"
        case .sleepDuration:    return "bed.double.fill"
        case .sleepConsistency: return "clock"
        case .customSleep:      return "slider.horizontal.3"
        case .checklistHabit: return "checklist"
        case .numericTarget:  return "chart.line.uptrend.xyaxis"
        case .mixedGoal:      return "square.grid.2x2"
        }
    }

    var templateDescription: String {
        switch self {
        case .calorieTarget:  return "Track daily calorie intake"
        case .proteinGoal:    return "Track daily protein intake"
        case .fullNutrition:  return "Track calories + protein together"
        case .customDiet:     return "Build your own diet goal"
        case .liftingProgram: return "Track workout days and exercises"
        case .cardioProgram:  return "Track cardio sessions"
        case .fullFitness:    return "Track both lifting and cardio"
        case .customExercise: return "Build your own exercise goal"
        case .sleepDuration:    return "Track hours slept each night"
        case .sleepConsistency: return "Track bedtime consistency"
        case .customSleep:      return "Build your own sleep goal"
        case .checklistHabit: return "Daily checklist items to complete"
        case .numericTarget:  return "Track a number toward a goal"
        case .mixedGoal:      return "Combine checklist and numeric metrics"
        }
    }
}

// MARK: - SubMetricSpec

struct SubMetricSpec {
    let name: String
    let unit: String
    let targetValue: Double
    let type: String
}

// MARK: - Main View

struct GoalCreationWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let categoryLevel: CategoryLevel

    @State private var step = 1
    @State private var selectedTemplate: GoalTemplate?

    // Common fields
    @State private var goalName = ""
    @State private var frequency = "daily"
    @State private var xpValue = 15
    @State private var hasTargetDate = false
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    // Diet
    @State private var calorieLimit = 2000
    @State private var proteinTarget = 120

    // Exercise
    @State private var liftingDays = 3
    @State private var cardioDays = 3
    @State private var cardioMinutes = 30

    // Sleep
    @State private var sleepHours = 8.0

    // Checklist habit
    @State private var checklistItems: [String] = []
    @State private var newChecklistItemText = ""

    // Numeric target
    @State private var metricName = ""
    @State private var metricUnit = ""
    @State private var metricTargetStr = ""

    // Custom / Mixed drafts
    @State private var customDrafts: [SubMetricDraft] = []

    private var stepTitle: String {
        switch step {
        case 1: return "Choose Template"
        case 2: return "Goal Details"
        default: return "Review"
        }
    }

    private var templates: [GoalTemplate] {
        switch categoryLevel.name {
        case "Diet":     return [.calorieTarget, .proteinGoal, .fullNutrition, .customDiet]
        case "Exercise": return [.liftingProgram, .cardioProgram, .fullFitness, .customExercise]
        case "Sleep":    return [.sleepDuration, .sleepConsistency, .customSleep]
        default:         return [.checklistHabit, .numericTarget, .mixedGoal]
        }
    }

    private var isFrequencyLocked: Bool {
        guard let t = selectedTemplate else { return false }
        switch t {
        case .calorieTarget, .proteinGoal, .fullNutrition,
             .sleepDuration, .sleepConsistency: return true
        default: return false
        }
    }

    private var defaultFrequency: String {
        guard let t = selectedTemplate else { return "daily" }
        switch t {
        case .liftingProgram, .cardioProgram, .fullFitness: return "weekly"
        default: return "daily"
        }
    }

    private var canAdvanceToStep2: Bool { selectedTemplate != nil }

    private var canAdvanceToStep3: Bool {
        guard let t = selectedTemplate else { return false }
        let name = goalName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return false }
        switch t {
        case .checklistHabit:
            return !checklistItems.isEmpty
        case .numericTarget:
            return !metricName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   Double(metricTargetStr) != nil
        case .customDiet, .customExercise, .customSleep, .mixedGoal:
            return !customDrafts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
        default:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar

                    ScrollView {
                        VStack(spacing: 20) {
                            switch step {
                            case 1:  step1View
                            case 2:  step2View
                            default: step3View
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step == 1 {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Button("Back") { step -= 1 }
                            .foregroundStyle(AppTheme.accentBlue)
                    }
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? AppTheme.accentBlue : AppTheme.backgroundSecondary)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(AppTheme.backgroundSecondary)
    }

    // MARK: - Step 1: Template Selection

    private var step1View: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: categoryLevel.icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accentBlue)
                Text(categoryLevel.name)
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(templates) { template in
                TemplateCard(
                    template: template,
                    isSelected: selectedTemplate == template,
                    onTap: {
                        selectedTemplate = template
                        applyTemplateDefaults(template)
                    }
                )
            }

            GradientSaveButton(title: "Next →", isEnabled: canAdvanceToStep2) {
                step = 2
            }
        }
    }

    private func applyTemplateDefaults(_ t: GoalTemplate) {
        switch t {
        case .calorieTarget:  goalName = "Daily Calories"; frequency = "daily"; xpValue = 20
        case .proteinGoal:    goalName = "Daily Protein"; frequency = "daily"; xpValue = 15
        case .fullNutrition:  goalName = "Full Nutrition"; frequency = "daily"; xpValue = 25
        case .liftingProgram: goalName = "Lifting"; frequency = "weekly"; xpValue = 25
        case .cardioProgram:  goalName = "Cardio"; frequency = "weekly"; xpValue = 20
        case .fullFitness:    goalName = "Full Fitness"; frequency = "weekly"; xpValue = 30
        case .sleepDuration:    goalName = "Sleep"; frequency = "daily"; xpValue = 15
        case .sleepConsistency: goalName = "Sleep Consistency"; frequency = "daily"; xpValue = 10
        default:
            goalName = ""; frequency = "daily"; xpValue = 15
        }
    }

    // MARK: - Step 2: Goal Details

    private var step2View: some View {
        VStack(spacing: 20) {
            // Goal name + common fields
            FormCard(header: "Goal") {
                ThemedTextField("Goal name", text: $goalName)
                if !isFrequencyLocked {
                    Divider().background(AppTheme.backgroundSecondary)
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
                Divider().background(AppTheme.backgroundSecondary)
                Stepper("XP Value: \(xpValue)", value: $xpValue, in: 5...100, step: 5)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Template-specific fields
            templateFields

            // Schedule
            FormCard(header: "Schedule") {
                Toggle("Set target date", isOn: $hasTargetDate)
                    .tint(AppTheme.accentBlue)
                    .foregroundStyle(AppTheme.textPrimary)
                if hasTargetDate {
                    DatePicker(
                        "Target date",
                        selection: $targetDate,
                        in: (Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())...,
                        displayedComponents: .date
                    )
                    .foregroundStyle(AppTheme.textPrimary)
                    .tint(AppTheme.accentBlue)
                }
            }

            GradientSaveButton(title: "Review →", isEnabled: canAdvanceToStep3) {
                step = 3
            }
        }
    }

    @ViewBuilder
    private var templateFields: some View {
        switch selectedTemplate {
        case .calorieTarget:
            FormCard(header: "Calorie Target") {
                Stepper("Daily limit: \(calorieLimit) kcal", value: $calorieLimit, in: 500...5000, step: 50)
                    .foregroundStyle(AppTheme.textPrimary)
                Divider().background(AppTheme.backgroundSecondary)
                Text("We will track this against your food logs automatically.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

        case .proteinGoal:
            FormCard(header: "Protein Target") {
                Stepper("Daily target: \(proteinTarget)g", value: $proteinTarget, in: 20...300, step: 5)
                    .foregroundStyle(AppTheme.textPrimary)
            }

        case .fullNutrition:
            FormCard(header: "Nutrition Targets") {
                Stepper("Calories: \(calorieLimit) kcal", value: $calorieLimit, in: 500...5000, step: 50)
                    .foregroundStyle(AppTheme.textPrimary)
                Divider().background(AppTheme.backgroundSecondary)
                Stepper("Protein: \(proteinTarget)g", value: $proteinTarget, in: 20...300, step: 5)
                    .foregroundStyle(AppTheme.textPrimary)
            }

        case .liftingProgram:
            FormCard(header: "Program") {
                Stepper("Target days/week: \(liftingDays)", value: $liftingDays, in: 1...7)
                    .foregroundStyle(AppTheme.textPrimary)
                Divider().background(AppTheme.backgroundSecondary)
                Text("Check off each day you complete a lifting session.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

        case .cardioProgram:
            FormCard(header: "Program") {
                Stepper("Target days/week: \(cardioDays)", value: $cardioDays, in: 1...7)
                    .foregroundStyle(AppTheme.textPrimary)
                Divider().background(AppTheme.backgroundSecondary)
                Stepper("Target minutes/session: \(cardioMinutes)", value: $cardioMinutes, in: 10...120, step: 5)
                    .foregroundStyle(AppTheme.textPrimary)
            }

        case .fullFitness:
            FormCard(header: "Program") {
                Stepper("Lifting days/week: \(liftingDays)", value: $liftingDays, in: 1...7)
                    .foregroundStyle(AppTheme.textPrimary)
                Divider().background(AppTheme.backgroundSecondary)
                Stepper("Cardio days/week: \(cardioDays)", value: $cardioDays, in: 1...7)
                    .foregroundStyle(AppTheme.textPrimary)
            }

        case .sleepDuration:
            FormCard(header: "Sleep Target") {
                Stepper("Target: \(sleepHours.formatted()) hrs", value: $sleepHours, in: 4...12, step: 0.5)
                    .foregroundStyle(AppTheme.textPrimary)
            }

        case .sleepConsistency:
            FormCard(header: "Consistency") {
                Text("Check off each morning you woke up on schedule.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

        case .checklistHabit:
            checklistHabitFields

        case .numericTarget:
            numericTargetFields

        case .customDiet, .customExercise, .customSleep, .mixedGoal:
            customDraftFields

        case .none:
            EmptyView()
        }
    }

    private var checklistHabitFields: some View {
        FormCard(
            header: "Checklist Items",
            footer: checklistItems.isEmpty ? "At least one item is required." : nil,
            footerColor: AppTheme.danger
        ) {
            ForEach(Array(checklistItems.enumerated()), id: \.offset) { i, item in
                HStack {
                    Text(item).foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        checklistItems.remove(at: i)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(AppTheme.danger)
                    }
                    .buttonStyle(.plain)
                }
                Divider().background(AppTheme.backgroundSecondary)
            }
            HStack {
                ThemedTextField("New item", text: $newChecklistItemText)
                Button("Add") {
                    let trimmed = newChecklistItemText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    checklistItems.append(trimmed)
                    newChecklistItemText = ""
                }
                .foregroundStyle(AppTheme.accentBlue)
                .disabled(newChecklistItemText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var numericTargetFields: some View {
        FormCard(header: "Metric") {
            ThemedTextField("Metric name (e.g. Pages read)", text: $metricName)
            Divider().background(AppTheme.backgroundSecondary)
            HStack {
                ThemedTextField("Unit (e.g. pages)", text: $metricUnit)
                ThemedTextField("Target", text: $metricTargetStr)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 80)
            }
            .font(.subheadline)
        }
    }

    private var customDraftFields: some View {
        FormCard(
            header: "Sub-Metrics",
            footer: customDrafts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
                ? "At least one sub-metric is required." : nil,
            footerColor: AppTheme.danger
        ) {
            ForEach($customDrafts) { $draft in
                WizardSubMetricRow(draft: $draft)
                    .padding(.vertical, 2)
                Divider().background(AppTheme.backgroundSecondary)
            }
            Button("+ Add Sub-Metric") {
                customDrafts.append(SubMetricDraft())
            }
            .foregroundStyle(AppTheme.accentBlue)
        }
    }

    // MARK: - Step 3: Review

    private var step3View: some View {
        VStack(spacing: 20) {
            FormCard(header: "Summary") {
                HStack {
                    Image(systemName: categoryLevel.icon)
                        .foregroundStyle(AppTheme.accentBlue)
                    Text(categoryLevel.name)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(xpValue) XP")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentBlue)
                }
                Divider().background(AppTheme.backgroundSecondary)
                Text(goalName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(frequency.capitalized) · \(xpValue) XP")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                if hasTargetDate {
                    Text("Target: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            let specs = subMetricSpecs()
            if !specs.isEmpty {
                FormCard(header: "Sub-Metrics") {
                    ForEach(Array(specs.enumerated()), id: \.offset) { i, spec in
                        HStack {
                            Image(systemName: spec.type == "checklist" ? "checkmark.circle" : "chart.bar")
                                .foregroundStyle(AppTheme.accentBlue)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(spec.name)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                if spec.type == "numeric" {
                                    Text("Target: \(spec.targetValue.formatted()) \(spec.unit)")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        if i < specs.count - 1 {
                            Divider().background(AppTheme.backgroundSecondary)
                        }
                    }
                }
            }

            Button {
                create()
            } label: {
                Text("Create Goal")
                    .font(.headline).fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppTheme.xpGradient)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.accentBlue.opacity(0.4), radius: 12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - SubMetric Computation

    private func subMetricSpecs() -> [SubMetricSpec] {
        guard let t = selectedTemplate else { return [] }
        switch t {
        case .calorieTarget:
            return [SubMetricSpec(name: "Calories", unit: "kcal", targetValue: Double(calorieLimit), type: "numeric")]
        case .proteinGoal:
            return [SubMetricSpec(name: "Protein", unit: "g", targetValue: Double(proteinTarget), type: "numeric")]
        case .fullNutrition:
            return [
                SubMetricSpec(name: "Calories", unit: "kcal", targetValue: Double(calorieLimit), type: "numeric"),
                SubMetricSpec(name: "Protein",  unit: "g",    targetValue: Double(proteinTarget), type: "numeric")
            ]
        case .liftingProgram:
            return [SubMetricSpec(name: "Lifting Session", unit: "", targetValue: 1, type: "checklist")]
        case .cardioProgram:
            return [
                SubMetricSpec(name: "Cardio Session", unit: "",    targetValue: 1, type: "checklist"),
                SubMetricSpec(name: "Duration",       unit: "min", targetValue: Double(cardioMinutes), type: "numeric")
            ]
        case .fullFitness:
            return [
                SubMetricSpec(name: "Lifting Session", unit: "", targetValue: 1, type: "checklist"),
                SubMetricSpec(name: "Cardio Session",  unit: "", targetValue: 1, type: "checklist")
            ]
        case .sleepDuration:
            return [SubMetricSpec(name: "Hours Slept", unit: "hrs", targetValue: sleepHours, type: "numeric")]
        case .sleepConsistency:
            return [SubMetricSpec(name: "Bedtime on Schedule", unit: "", targetValue: 1, type: "checklist")]
        case .checklistHabit:
            return checklistItems.map {
                SubMetricSpec(name: $0, unit: "", targetValue: 1, type: "checklist")
            }
        case .numericTarget:
            let target = Double(metricTargetStr) ?? 0
            return [SubMetricSpec(name: metricName, unit: metricUnit, targetValue: target, type: "numeric")]
        case .customDiet, .customExercise, .customSleep, .mixedGoal:
            return customDrafts
                .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { draft in
                    SubMetricSpec(
                        name: draft.name.trimmingCharacters(in: .whitespaces),
                        unit: draft.type == "checklist" ? "" : draft.unit,
                        targetValue: draft.type == "checklist" ? 1 : (Double(draft.targetValue) ?? 0),
                        type: draft.type
                    )
                }
        }
    }

    // MARK: - Create

    private func create() {
        let goal = Goal(
            name: goalName.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            xpValue: xpValue,
            targetDate: hasTargetDate ? targetDate : nil
        )
        modelContext.insert(goal)
        goal.category = categoryLevel

        for spec in subMetricSpecs() {
            let metric = SubMetric(
                name: spec.name,
                unit: spec.unit,
                targetValue: spec.targetValue,
                type: spec.type
            )
            modelContext.insert(metric)
            metric.goal = goal
        }

        do {
            try modelContext.save()
        } catch {
            print("GoalCreationWizardView create failed: \(error)")
        }
        dismiss()
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: GoalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: template.templateIcon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppTheme.accentBlue : AppTheme.textSecondary)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(template.rawValue)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(template.templateDescription)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentBlue)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppTheme.accentBlue : AppTheme.accentBlue.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wizard SubMetric Row

private struct WizardSubMetricRow: View {
    @Binding var draft: SubMetricDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThemedTextField("Name", text: $draft.name)

            Picker("Mode", selection: $draft.type) {
                Text("Numeric").tag("numeric")
                Text("Checklist").tag("checklist")
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.type) { _, newType in
                if newType == "checklist" {
                    draft.unit = ""
                    draft.targetValue = "1"
                }
            }

            if draft.type == "numeric" {
                HStack {
                    ThemedTextField("Unit (e.g. lbs, miles)", text: $draft.unit)
                    ThemedTextField("Target", text: $draft.targetValue)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: 80)
                }
                .font(.subheadline)
            } else {
                Text("Marks a single daily completion.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
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
        configurations: config
    )
    let cat = CategoryLevel(name: "Diet", icon: "fork.knife")
    container.mainContext.insert(cat)
    return GoalCreationWizardView(categoryLevel: cat)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
