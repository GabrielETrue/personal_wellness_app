import SwiftUI
import SwiftData

struct ClaudeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIInsight.date, order: .reverse) private var insights: [AIInsight]

    @State private var isGenerating = false
    @State private var isGeneratingPush = false
    @State private var quickPushText: String?
    @State private var showingQuickPush = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        generateButtonsSection

                        if insights.isEmpty {
                            emptyStateView
                        } else {
                            insightsFeedSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Claude")
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingQuickPush) {
                if let text = quickPushText {
                    QuickPushView(text: text)
                }
            }
        }
    }

    // MARK: - Section A: Generate Buttons

    private var generateButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isGenerating = true
                    _ = await InsightGenerationService.generateOnDemand(context: modelContext)
                    isGenerating = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView().tint(AppTheme.textPrimary)
                        Text("Generating…")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate Full Summary")
                    }
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.xpGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)
            .disabled(isGenerating || isGeneratingPush)

            Button {
                Task {
                    isGeneratingPush = true
                    let stats = GoalStatsService.computeAppStats(in: modelContext)
                    if let text = try? await ClaudeService.generateQuickPush(stats: stats) {
                        quickPushText = text
                        showingQuickPush = true
                    }
                    isGeneratingPush = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingPush {
                        ProgressView().tint(AppTheme.accentPurple)
                        Text("Generating…")
                    } else {
                        Image(systemName: "bolt.fill")
                        Text("Quick Push")
                    }
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(isGeneratingPush ? AppTheme.textSecondary : AppTheme.accentPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentPurple, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(isGenerating || isGeneratingPush)
        }
    }

    // MARK: - Section B: Feed

    private var insightsFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INSIGHTS")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(AppTheme.accentBlue)
                .kerning(1.2)

            ForEach(insights) { insight in
                NavigationLink(destination: InsightDetailView(insight: insight)) {
                    InsightCard(insight: insight)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section C: Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.accentPurple.opacity(0.4), radius: 20)
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.accentPurple.opacity(0.6), radius: 8)
            }
            .padding(.top, 32)

            Text("No insights yet")
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Tap Generate Full Summary to get your first insight")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

// MARK: - Insight Card

private struct InsightCard: View {
    let insight: AIInsight

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d 'at' h:mm a"
        return f.string(from: insight.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !insight.hasBeenRead {
                Circle()
                    .fill(AppTheme.accentBlue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)
            } else {
                Spacer().frame(width: 8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(dateString)
                    .font(.caption).fontWeight(.medium)
                    .foregroundStyle(AppTheme.accentBlue)

                Text(String(insight.content.prefix(150)))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentBlue.opacity(0.15), lineWidth: 1)
                )
        )
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
    let insight = AIInsight(content: """
    QUOTE:
    "The impediment to action advances action. What stands in the way becomes the way." — Marcus Aurelius

    REFLECTION:
    Three days of sub-7h sleep while maintaining workout frequency — the discipline is there but the recovery isn't. Sleep is the multiplier, not a reward.

    PROGRESS RECAP:
    • Diet: 2,050 kcal avg, protein improving
    • Exercise: 3 lifting sessions — solid week
    • Sleep: 6.4h avg — below 8h goal, declining trend
    """)
    container.mainContext.insert(insight)

    return ClaudeView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
