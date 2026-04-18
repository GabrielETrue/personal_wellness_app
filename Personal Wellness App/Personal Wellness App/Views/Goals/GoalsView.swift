import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categoryLevels: [CategoryLevel]

    @State private var selectedCategoryName = "Diet"
    @State private var showingAddGoal = false
    @State private var addGoalCategory: CategoryLevel?

    private let categoryOrder = ["Diet", "Exercise", "Sleep", "Custom"]

    private var selectedCategory: CategoryLevel? {
        categoryLevels.first { $0.name == selectedCategoryName }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedCategoryName) {
                ForEach(categoryOrder, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            if let category = selectedCategory {
                let sorted = category.goals.sorted { $0.createdDate < $1.createdDate }
                if sorted.isEmpty {
                    ContentUnavailableView(
                        "No Goals",
                        systemImage: category.icon,
                        description: Text("Tap + to add your first \(category.name) goal.")
                    )
                } else {
                    List {
                        ForEach(sorted) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRow(goal: goal)
                            }
                        }
                        .onDelete { offsets in deleteGoals(at: offsets, from: sorted) }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addGoalCategory = selectedCategory
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedCategory == nil)
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            if let category = addGoalCategory {
                AddGoalView(categoryLevel: category)
            }
        }
    }
    private func deleteGoals(at offsets: IndexSet, from goals: [Goal]) {
        for index in offsets {
            let goal = goals[index]
            for metric in goal.subMetrics {
                for entry in metric.logs {
                    modelContext.delete(entry)
                }
                modelContext.delete(metric)
            }
            modelContext.delete(goal)
        }
        try? modelContext.save()
    }
}

private struct GoalRow: View {
    let goal: Goal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                HStack(spacing: 6) {
                    FrequencyBadge(frequency: goal.frequency)
                    if !goal.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text("\(goal.xpValue) XP")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FrequencyBadge: View {
    let frequency: String

    var body: some View {
        Text(frequency.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(frequency == "daily" ? Color.blue.opacity(0.15) : Color.purple.opacity(0.15))
            .foregroundStyle(frequency == "daily" ? .blue : .purple)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
    .modelContainer(for: [PlayerProfile.self, CategoryLevel.self, LevelEvent.self,
                           Goal.self, SubMetric.self, LogEntry.self], inMemory: true)
}
