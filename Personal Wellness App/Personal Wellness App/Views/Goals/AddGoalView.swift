import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let categoryLevel: CategoryLevel

    @State private var name = ""
    @State private var frequency = "daily"
    @State private var xpValue = 10
    @State private var drafts: [SubMetricDraft] = []

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !drafts.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Goal") {
                            ThemedTextField("Goal name", text: $name)
                            Divider().background(AppTheme.backgroundSecondary)
                            Picker("Frequency", selection: $frequency) {
                                Text("Daily").tag("daily")
                                Text("Weekly").tag("weekly")
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            Divider().background(AppTheme.backgroundSecondary)
                            Stepper("XP Value: \(xpValue)", value: $xpValue, in: 5...100, step: 5)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        FormCard(
                            header: "Sub-Metrics",
                            footer: drafts.isEmpty ? "At least one sub-metric is required." : nil,
                            footerColor: AppTheme.danger
                        ) {
                            ForEach($drafts) { $draft in
                                SubMetricDraftRow(draft: $draft)
                                Divider().background(AppTheme.backgroundSecondary)
                            }
                            Button("+ Add Sub-Metric") {
                                drafts.append(SubMetricDraft())
                            }
                            .foregroundStyle(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Goal", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func save() {
        let goal = Goal(
            name: name.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            xpValue: xpValue
        )
        modelContext.insert(goal)
        goal.category = categoryLevel

        for draft in drafts where !draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let metric = SubMetric(
                name: draft.name.trimmingCharacters(in: .whitespaces),
                unit: draft.unit,
                targetValue: Double(draft.targetValue) ?? 0
            )
            modelContext.insert(metric)
            metric.goal = goal
        }

        try? modelContext.save()
        dismiss()
    }
}

struct SubMetricDraft: Identifiable {
    let id = UUID()
    var name = ""
    var unit = ""
    var targetValue = ""
}

private struct SubMetricDraftRow: View {
    @Binding var draft: SubMetricDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThemedTextField("Name", text: $draft.name)
            HStack {
                ThemedTextField("Unit (e.g. kg, miles)", text: $draft.unit)
                ThemedTextField("Target", text: $draft.targetValue)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 80)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Shared Form Helpers

struct FormCard<Content: View>: View {
    let header: String
    var footer: String? = nil
    var footerColor: Color = AppTheme.textSecondary
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.accentBlue)
                .kerning(1.1)
                .padding(.horizontal)
                .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentBlue.opacity(0.15), lineWidth: 1)
                    )
            )

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(footerColor)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
    }
}

struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundStyle(AppTheme.textPrimary)
            .tint(AppTheme.accentBlue)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: PlayerProfile.self, CategoryLevel.self, Goal.self, SubMetric.self,
        configurations: config
    )
    let cat = CategoryLevel(name: "Diet", icon: "fork.knife")
    container.mainContext.insert(cat)
    return AddGoalView(categoryLevel: cat)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
