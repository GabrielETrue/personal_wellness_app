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
                    } else {
                        ForEach(goal.subMetrics) { metric in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(metric.name)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Target: \(metric.targetValue.formatted()) \(metric.unit)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                            .listRowBackground(AppTheme.backgroundCard)
                        }
                    }
                } header: {
                    Text("Sub-Metrics")
                        .foregroundStyle(AppTheme.accentBlue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .kerning(1.1)
                }

                Section {
                    if recentLogs.isEmpty {
                        Text("No logs yet")
                            .foregroundStyle(AppTheme.textSecondary)
                            .listRowBackground(AppTheme.backgroundCard)
                    } else {
                        ForEach(recentLogs) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.value.formatted())
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
                Button("Log Progress") { showingLogProgress = true }
                    .foregroundStyle(AppTheme.accentBlue)
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
    .preferredColorScheme(.dark)
}
