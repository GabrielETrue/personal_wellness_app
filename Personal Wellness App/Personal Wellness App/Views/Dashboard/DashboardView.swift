import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [PlayerProfile]
    @Query private var categories: [CategoryLevel]
    @Query private var logEntries: [LogEntry]
    @Query private var foodLogs: [FoodLog]
    @Query private var liftingEntries: [LiftingEntry]
    @Query private var cardioEntries: [CardioEntry]
    @Query private var sleepLogs: [SleepLog]

    @State private var selectedCategory: CategoryLevel?
    @State private var recentActivities: [ActivityItem] = []

    private let categoryOrder = ["Diet", "Exercise", "Sleep", "Custom"]

    private var sortedCategories: [CategoryLevel] {
        categories.sorted {
            (categoryOrder.firstIndex(of: $0.name) ?? 99) <
            (categoryOrder.firstIndex(of: $1.name) ?? 99)
        }
    }

    private var activityTitle: String {
        selectedCategory.map { "Recent \($0.name) Activity" } ?? "Recent Activity"
    }

    private var logCount: Int {
        foodLogs.count + logEntries.count + liftingEntries.count + cardioEntries.count + sleepLogs.count
    }

    private func refreshActivities() {
        recentActivities = DashboardService.recentActivity(
            in: modelContext,
            category: selectedCategory,
            limit: 10
        )
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
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

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
                        RecentActivitySection(title: activityTitle, activities: recentActivities)
                    }
                    .padding()
                    .onChange(of: selectedCategory?.id) { _, newID in
                        refreshActivities()
                        guard newID != nil else { return }
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo("sectionC", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: logCount) { _, _ in refreshActivities() }
                }
            }
        }
        .navigationTitle("Dashboard")
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { refreshActivities() }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Level \(player.globalLevel)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            GradientProgressBar(value: progress, height: 10)
            HStack {
                Spacer()
                Text("\(remaining) XP to next level")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accentBlue.opacity(0.3), lineWidth: 1)
                )
        )
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
                    .foregroundStyle(AppTheme.accentBlue)
                    .shadow(color: AppTheme.accentBlue.opacity(0.6), radius: 4)
                Spacer()
                Text("Lv \(category.level)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.accentPurple.opacity(0.2))
                    .foregroundStyle(AppTheme.accentPurple)
                    .clipShape(Capsule())
            }

            Text(category.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            GradientProgressBar(value: max(0, min(xpProgress, 1.0)))

            HStack {
                if streak > 0 {
                    Text("🔥 \(streak) day streak")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if loggedToday {
                    Text("✅")
                        .font(.caption)
                } else {
                    Text("Nothing logged today")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppTheme.accentBlue.opacity(0.12) : AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? AppTheme.accentBlue : AppTheme.accentBlue.opacity(0.15),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
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
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            if activeGoals.isEmpty {
                Text("No active goals. Add one in the Goals tab.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
                    GoalProgressRow(goal: goal)
                    if index < activeGoals.count - 1 {
                        Divider().overlay(AppTheme.backgroundSecondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accentPurple.opacity(0.3), lineWidth: 1)
                )
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
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(goal.xpValue) XP")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentBlue)
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
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(todayTotal.formatted())/\(metric.targetValue.formatted()) \(metric.unit)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            GradientProgressBar(value: progress, height: 6)
        }
    }
}

// MARK: - Section D: Recent Activity

private struct RecentActivitySection: View {
    let title: String
    let activities: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.accentBlue)
                .kerning(1.2)

            if activities.isEmpty {
                Text("No recent activity.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, item in
                        ActivityRow(item: item)
                            .padding(.vertical, 10)
                        if index < activities.count - 1 {
                            Divider()
                                .background(AppTheme.backgroundSecondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.backgroundCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.accentBlue.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(AppTheme.accentBlue)
                .shadow(color: AppTheme.accentBlue.opacity(0.5), radius: 4)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(relativeTime)
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
    .preferredColorScheme(.dark)
}
