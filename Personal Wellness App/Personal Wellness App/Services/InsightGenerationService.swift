import Foundation
import SwiftData

struct InsightGenerationService {

    @MainActor
    static func generateAndSchedule(context: ModelContext) async {
        let stats = GoalStatsService.computeAppStats(in: context)
        do {
            let insight = try await ClaudeService.generateInsight(stats: stats, context: context)
            let preview = String(insight.content.prefix(100))
            NotificationService.sendImmediateNotification(
                title: "Your Daily Wellness Insight is Ready",
                body: preview
            )
            NotificationService.scheduleDailySummary(at: 4, minute: 0)
        } catch {
            print("InsightGenerationService: generateAndSchedule failed: \(error)")
        }
    }

    @MainActor
    static func generateOnDemand(context: ModelContext) async -> AIInsight? {
        let stats = GoalStatsService.computeAppStats(in: context)
        do {
            return try await ClaudeService.generateInsight(stats: stats, context: context)
        } catch {
            print("InsightGenerationService: generateOnDemand failed: \(error)")
            return nil
        }
    }
}
