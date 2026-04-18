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
            Form {
                Section("Goal") {
                    TextField("Goal name", text: $name)
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                    }
                    Stepper("XP Value: \(xpValue)", value: $xpValue, in: 5...100, step: 5)
                }

                Section {
                    ForEach($drafts) { $draft in
                        SubMetricDraftRow(draft: $draft)
                    }
                    .onDelete { drafts.remove(atOffsets: $0) }
                    Button("Add Sub-Metric") {
                        drafts.append(SubMetricDraft())
                    }
                } header: {
                    Text("Sub-Metrics")
                } footer: {
                    if drafts.isEmpty {
                        Text("At least one sub-metric is required.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
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
            TextField("Name", text: $draft.name)
            HStack {
                TextField("Unit (e.g. kg, miles)", text: $draft.unit)
                TextField("Target", text: $draft.targetValue)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 80)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
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
}
