import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [PlayerProfile]
    @Query private var categories: [CategoryLevel]
    // Observed so the view refreshes when any log type changes
    @Query private var logEntries: [LogEntry]
    @Query private var foodLogs: [FoodLog]
    @Query private var liftingEntries: [LiftingEntry]
    @Query private var cardioEntries: [CardioEntry]
    @Query private var sleepLogs: [SleepLog]

    @State private var selectedCategory: CategoryLevel?

    private let categoryOrder = ["Diet", "Exercise", "Sleep", "Custom"]

    private var sortedCategories: [CategoryLevel] {
        categories.sorted {
            (categoryOrder.firstIndex(of: $0.name) ?? 99) <
            (categoryOrder.firstIndex(of: $1.name) ?? 99)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 24) {

                    // Section A — Player Header
                    if let player = players.first {
                        PlayerHeaderSection(greeting: greeting, player: player)
                    }

                    // Section B — Category Cards
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sortedCategories) { category in
                            CategoryCard(
                                category: category,
                                context: modelContext,
                                isSelected: selectedCategory?.id == category.id,
                                onTap: { selectedCategory = category }
                            )
                        }
                    }

                    // Section C — Category Detail
                    if let category = selectedCategory {
                        CategoryDetailSection(
                            category: category,
                            onDismiss: { selectedCategory = nil }
                        )
                        .id("sectionC")
                    }

                    // Section D — Recent Activity
                    RecentActivitySection(context: modelContext)
                }
                .padding()
                .onChange(of: selectedCategory?.id) { _, newID in
                    guard newID != nil else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo("sectionC", anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - Section A: Player Header

private struct PlayerHeaderSection: View {
    let greeting: String
    let player: PlayerProfile

    private var xpForNextLevel: Int { max(1, 100 * player.globalLevel) }
    private var progress: Double { Double(player.globalXP) / Double(xpForNextLevel) }
    private var remaining: Int { xpForNextLevel - player.globalXP }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Level \(player.globalLevel)")
                .font(.largeTitle)
                .fontWeight(.bold)
            ProgressView(value: max(0, min(progress, 1.0)))
                .tint(Color.accentColor)
            HStack {
                Spacer()
                Text("\(remaining) XP to next level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Section B: Category Card

private struct CategoryCard: View {
    let category: CategoryLevel
    let context: ModelContext
    let isSelected: Bool
    let onTap: () -> Void

    private var xpForNextLevel: Int { max(1, 100 * category.level) }
    private var xpProgress: Double { Double(category.xp) / Double(xpForNextLevel) }
    private var streak: Int { DashboardService.streak(for: category, in: context) }
    private var loggedToday: Bool { DashboardService.hasLoggedToday(for: category, in: context) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text("Lv \(category.level)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            Text(category.name)
                .font(.subheadline)
                .fontWeight(.semibold)

            ProgressView(value: max(0, min(xpProgress, 1.0)))
                .tint(.accentColor)

            HStack {
                if streak > 0 {
                    Text("🔥 \(streak) day streak")
                        .font(.caption2)
                }
                Spacer()
                if loggedToday {
                    Text("✅")
                        .font(.caption)
                } else {
                    Text("Nothing logged today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Section C: Category Detail

private struct CategoryDetailSection: View {
    let category: CategoryLevel
    let onDismiss: () -> Void

    private var activeGoals: [Goal] {
        category.goals
            .filter(\.isActive)
            .sorted { $0.createdDate < $1.createdDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.name)
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if activeGoals.isEmpty {
                Text("No active goals. Add one in the Goals tab.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
                    GoalProgressRow(goal: goal)
                    if index < activeGoals.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

private struct GoalProgressRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(goal.xpValue) XP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(goal.subMetrics) { metric in
                SubMetricProgressRow(metric: metric)
            }
        }
    }
}

private struct SubMetricProgressRow: View {
    let metric: SubMetric

    private var todayTotal: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return metric.logs
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progress: Double {
        metric.targetValue > 0 ? min(todayTotal / metric.targetValue, 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(metric.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(todayTotal.formatted())/\(metric.targetValue.formatted()) \(metric.unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(.accentColor)
        }
    }
}

// MARK: - Section D: Recent Activity

private struct RecentActivitySection: View {
    let context: ModelContext

    var body: some View {
        let activities = DashboardService.recentActivity(in: context, limit: 10)
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if activities.isEmpty {
                Text("No recent activity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, item in
                    ActivityRow(item: item)
                    if index < activities.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

private struct ActivityRow: View {
    let item: ActivityItem

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: item.date, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(.subheadline)
                Text(relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            FoodLog.self, CustomNutrient.self, LiftingEntry.self, LiftingSet.self,
            CardioEntry.self, SleepLog.self, JournalEntry.self, AIInsight.self,
        configurations: config
    )

    let ctx = container.mainContext
    let player = PlayerProfile(globalXP: 65, globalLevel: 2)
    ctx.insert(player)

    let catData: [(String, String)] = [
        ("Diet", "fork.knife"), ("Exercise", "figure.run"),
        ("Sleep", "bed.double"), ("Custom", "star"),
    ]
    for (name, icon) in catData {
        let cat = CategoryLevel(name: name, icon: icon, xp: 40, level: 1)
        ctx.insert(cat)
        cat.player = player
    }

    let food = FoodLog(name: "Oatmeal", calories: 320, protein: 12)
    ctx.insert(food)

    let lift = LiftingEntry(exerciseName: "Bench Press")
    ctx.insert(lift)

    let sleep = SleepLog(hoursSlept: 7.5)
    ctx.insert(sleep)

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(container)
}
