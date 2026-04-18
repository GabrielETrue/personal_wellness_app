import SwiftUI
import SwiftData

struct GoalDetailView: View {
    let goal: Goal

    @State private var showingLogProgress = false

    private var recentLogs: [LogEntry] {
        Array(
            goal.subMetrics
                .flatMap(\.logs)
                .sorted { $0.date > $1.date }
                .prefix(7)
        )
    }

    var body: some View {
        List {
            Section("Sub-Metrics") {
                if goal.subMetrics.isEmpty {
                    Text("No sub-metrics").foregroundStyle(.secondary)
                } else {
                    ForEach(goal.subMetrics) { metric in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(metric.name)
                                Text("Target: \(metric.targetValue.formatted()) \(metric.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }

            Section("Recent Logs") {
                if recentLogs.isEmpty {
                    Text("No logs yet").foregroundStyle(.secondary)
                } else {
                    ForEach(recentLogs) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.value.formatted())
                                if !entry.notes.isEmpty {
                                    Text(entry.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Log Progress") { showingLogProgress = true }
                    .disabled(goal.subMetrics.isEmpty)
            }
        }
        .sheet(isPresented: $showingLogProgress) {
            LogProgressView(goal: goal)
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
    let goal = Goal(name: "Run 5K", frequency: "daily", xpValue: 20)
    let metric = SubMetric(name: "Distance", unit: "km", targetValue: 5)
    metric.goal = goal
    goal.subMetrics.append(metric)
    let entry = LogEntry(value: 3.2, notes: "Felt great")
    entry.subMetric = metric
    metric.logs.append(entry)
    container.mainContext.insert(goal)
    container.mainContext.insert(metric)
    container.mainContext.insert(entry)
    return NavigationStack {
        GoalDetailView(goal: goal)
    }
    .modelContainer(container)
}
