import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [PlayerProfile]
    @Query(sort: \CategoryLevel.name) private var categories: [CategoryLevel]
    @Query(sort: \LogEntry.date, order: .reverse) private var logEntries: [LogEntry]
    @Query(sort: \FoodLog.date, order: .reverse) private var foodLogs: [FoodLog]
    @Query(sort: \LiftingEntry.date, order: .reverse) private var liftingEntries: [LiftingEntry]
    @Query(sort: \CardioEntry.date, order: .reverse) private var cardioEntries: [CardioEntry]
    @Query(sort: \SleepLog.date, order: .reverse) private var sleepLogs: [SleepLog]
    @Query(sort: \WeightLog.date, order: .reverse) private var weightLogs: [WeightLog]

    @State private var selectedCategory: CategoryLevel?
    @State private var recentActivities: [ActivityItem] = []
    @State private var showingWeightLog = false
    @State private var showingEditSheet = false
    @State private var activityToEdit: ActivityItem?
    @State private var showingDeleteConfirmation = false
    @State private var activityToDelete: ActivityItem?
    @State private var showingActionSheet = false
    @State private var actionSheetItem: ActivityItem?

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
        foodLogs.count + logEntries.count + liftingEntries.count + cardioEntries.count + sleepLogs.count + weightLogs.count
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
                            PlayerHeaderSection(
                                greeting: greeting,
                                player: player,
                                onLogWeight: { showingWeightLog = true }
                            )
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

                        // Section C — Category Detail Graph
                        if let category = selectedCategory {
                            CategoryDetailGraphView(
                                category: category,
                                onDismiss: { selectedCategory = nil }
                            )
                            .id("sectionC")
                        }

                        // Section D — Recent Activity
                        RecentActivitySection(
                            title: activityTitle,
                            activities: recentActivities,
                            onLongPress: { item in
                                actionSheetItem = item
                                showingActionSheet = true
                            }
                        )
                    }
                    .padding()
                    .onChange(of: selectedCategory?.id) { _, newID in
                        refreshActivities()
                        guard newID != nil else { return }
                        DispatchQueue.main.async {
                            withAnimation { proxy.scrollTo("sectionC", anchor: .top) }
                        }
                    }
                    .onChange(of: logCount) { _, _ in refreshActivities() }
                }
            }
        }
        .navigationTitle("Dashboard")
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingWeightLog) { WeightLogView() }
        .sheet(isPresented: $showingEditSheet) {
            if let item = activityToEdit {
                editView(for: item)
            }
        }
        .confirmationDialog("Activity", isPresented: $showingActionSheet, titleVisibility: .hidden) {
            Button("Edit") {
                activityToEdit = actionSheetItem
                showingEditSheet = true
            }
            Button("Delete", role: .destructive) {
                activityToDelete = actionSheetItem
                showingDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Activity?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let item = activityToDelete { deleteActivityItem(item) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reverse any XP awarded for this entry.")
        }
        .task { refreshActivities() }
    }

    @ViewBuilder
    private func editView(for item: ActivityItem) -> some View {
        switch item.logType {
        case "food":    EditFoodLogView(recordID: item.recordID, onSave: refreshActivities)
        case "lifting": EditLiftingEntryView(recordID: item.recordID, onSave: refreshActivities)
        case "cardio":  EditCardioEntryView(recordID: item.recordID, onSave: refreshActivities)
        case "sleep":   EditSleepLogView(recordID: item.recordID, onSave: refreshActivities)
        case "logEntry": EditLogEntryView(recordID: item.recordID, onSave: refreshActivities)
        case "weight":  EditWeightLogView(recordID: item.recordID, onSave: refreshActivities)
        default:        EmptyView()
        }
    }

    private func deleteActivityItem(_ item: ActivityItem) {
        switch item.logType {
        case "food":
            if let logs = try? modelContext.fetch(FetchDescriptor<FoodLog>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                modelContext.delete(record)
            }
        case "lifting":
            if let logs = try? modelContext.fetch(FetchDescriptor<LiftingEntry>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                for set in record.sets { modelContext.delete(set) }
                modelContext.delete(record)
            }
        case "cardio":
            if let logs = try? modelContext.fetch(FetchDescriptor<CardioEntry>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                modelContext.delete(record)
            }
        case "sleep":
            if let logs = try? modelContext.fetch(FetchDescriptor<SleepLog>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                modelContext.delete(record)
            }
        case "logEntry":
            if let logs = try? modelContext.fetch(FetchDescriptor<LogEntry>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                reverseXP(for: record)
                modelContext.delete(record)
            }
        case "weight":
            if let logs = try? modelContext.fetch(FetchDescriptor<WeightLog>()),
               let record = logs.first(where: { $0.id == item.recordID }) {
                modelContext.delete(record)
            }
        default:
            break
        }
        do {
            try modelContext.save()
        } catch {
            print("deleteActivityItem save failed: \(error)")
        }
        refreshActivities()
    }

    private func reverseXP(for entry: LogEntry) {
        guard let metric = entry.subMetric,
              let goal = metric.goal,
              let category = goal.category else { return }
        category.xp = max(0, category.xp - goal.xpValue)
        if let player = category.player {
            player.globalXP = max(0, player.globalXP - goal.xpValue)
        }
    }
}

// MARK: - Section A: Player Header

private struct PlayerHeaderSection: View {
    let greeting: String
    let player: PlayerProfile
    let onLogWeight: () -> Void

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
                Button(action: onLogWeight) {
                    Text("⚖️ Log Weight")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .overlay(
                            Capsule().stroke(AppTheme.accentBlue, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
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
                    .font(.caption2).fontWeight(.semibold)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(AppTheme.accentPurple.opacity(0.2))
                    .foregroundStyle(AppTheme.accentPurple)
                    .clipShape(Capsule())
            }

            Text(category.name)
                .font(.subheadline).fontWeight(.semibold)
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
                    Text("✅").font(.caption)
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

// MARK: - Section D: Recent Activity

private struct RecentActivitySection: View {
    let title: String
    let activities: [ActivityItem]
    let onLongPress: (ActivityItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption).fontWeight(.semibold)
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
                        ActivityRow(item: item, onLongPress: { onLongPress(item) })
                            .padding(.vertical, 10)
                        if index < activities.count - 1 {
                            Divider().background(AppTheme.backgroundSecondary)
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
    let onLongPress: () -> Void

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
        .contentShape(Rectangle())
        .onLongPressGesture { onLongPress() }
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
            WeightLog.self,
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

    ctx.insert(FoodLog(name: "Oatmeal", calories: 320, protein: 12))
    ctx.insert(LiftingEntry(exerciseName: "Bench Press"))
    ctx.insert(SleepLog(hoursSlept: 7.5))
    ctx.insert(WeightLog(weightLbs: 178.5))

    return NavigationStack {
        DashboardView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
