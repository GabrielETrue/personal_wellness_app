import Foundation
import SwiftData

struct ClaudeService {

    @MainActor
    static func generateInsight(stats: AppStats, context: ModelContext) async throws -> AIInsight {
        let response = try await callAPI(
            systemPrompt: buildSystemPrompt(),
            userPrompt: buildUserPrompt(stats: stats)
        )
        let insight = AIInsight(content: response)
        context.insert(insight)
        do {
            try context.save()
        } catch {
            print("ClaudeService: failed to save insight: \(error)")
        }
        return insight
    }

    static func generateQuickPush(stats: AppStats) async throws -> String {
        let compact = buildCompactStats(stats: stats)
        let userPrompt = """
        Given these stats: \(compact)

        Give me a 2-3 sentence motivational push right now. Be direct, stoic, no fluff. End with one specific action to take in the next hour.
        """
        return try await callAPI(systemPrompt: buildSystemPrompt(), userPrompt: userPrompt)
    }

    // MARK: - Private

    private static func buildSystemPrompt() -> String {
        """
        You are a personal wellness coach integrated into a fitness tracking app. Your role is to provide daily insights based on the user's actual tracked data. Be candid, pragmatic, and direct. Avoid corporate wellness speak or hollow encouragement. The user wants to genuinely improve and needs honest assessment with specific actionable guidance. Channel the spirit of stoic philosophy — focus on what is within the user's control, acknowledge reality without dramatizing it, and push toward disciplined action. Keep your tone like a trusted mentor who respects the user enough to tell the truth. Never be preachy.
        """
    }

    private static func buildUserPrompt(stats: AppStats) -> String {
        var lines: [String] = []

        lines.append("TODAY IS \(stats.dayOfWeek.uppercased())")
        lines.append("")
        lines.append("PLAYER STATUS: Level \(stats.globalLevel), \(stats.globalXP) XP")
        lines.append("")

        // Diet
        lines.append("DIET (last 5 days + averages)")
        let d = stats.dietStats
        lines.append("Today: \(formatOpt(d.todayCalories, "kcal")), \(formatOpt(d.todayProtein, "g protein"))")
        lines.append("Yesterday: \(formatOpt(d.yesterdayCalories, "kcal")), \(formatOpt(d.yesterdayProtein, "g protein"))")
        lines.append("2 days ago: \(formatOpt(d.twoDaysAgoCalories, "kcal")), \(formatOpt(d.twoDaysAgoProtein, "g protein"))")
        lines.append("3 days ago: \(formatOpt(d.threeDaysAgoCalories, "kcal")), \(formatOpt(d.threeDaysAgoProtein, "g protein"))")
        lines.append("4 days ago: \(formatOpt(d.fourDaysAgoCalories, "kcal")), \(formatOpt(d.fourDaysAgoProtein, "g protein"))")
        lines.append("7-day average: \(formatOpt(d.sevenDayAverageCalories, "kcal")), \(formatOpt(d.sevenDayAverageProtein, "g protein"))")
        lines.append("30-day average: \(formatOpt(d.thirtyDayAverageCalories, "kcal")), \(formatOpt(d.thirtyDayAverageProtein, "g protein"))")
        lines.append("Calorie trend: \(d.calorieTrend) | Protein trend: \(d.proteinTrend)")
        lines.append("")

        // Exercise
        let e = stats.exerciseStats
        lines.append("EXERCISE (this week vs last week)")
        lines.append("Lifting: \(e.liftingDaysThisWeek) days (this week) vs \(e.liftingDaysLastWeek) days (last week)")
        lines.append("Cardio: \(e.cardioDaysThisWeek) days (this week) vs \(e.cardioDaysLastWeek) days (last week)")
        lines.append("Lifting streak: \(e.currentLiftingStreak) days | Cardio streak: \(e.currentCardioStreak) days")
        lines.append("Total sets this week: \(e.totalSetsThisWeek)")
        lines.append("Total cardio minutes this week: \(String(format: "%.0f", e.totalCardioMinutesThisWeek))")
        if !e.recentPRs.isEmpty {
            lines.append("Recent PRs: \(e.recentPRs.joined(separator: ", "))")
        }
        lines.append("")

        // Sleep
        let s = stats.sleepStats
        lines.append("SLEEP (last 5 nights + averages)")
        lines.append("Last night: \(formatOpt(s.lastNight, "h"))")
        lines.append("2 nights ago: \(formatOpt(s.twoDaysAgo, "h"))")
        lines.append("3 nights ago: \(formatOpt(s.threeDaysAgo, "h"))")
        lines.append("4 nights ago: \(formatOpt(s.fourDaysAgo, "h"))")
        lines.append("5 nights ago: \(formatOpt(s.fiveDaysAgo, "h"))")
        lines.append("7-night average: \(formatOpt(s.sevenDayAverage, "h"))")
        lines.append("30-night average: \(formatOpt(s.thirtyDayAverage, "h"))")
        lines.append("Goal: \(String(format: "%.1f", s.goalHours))h | Trend: \(s.trend)")
        lines.append("")

        // Weight
        let w = stats.weightStats
        lines.append("WEIGHT")
        lines.append("Current: \(formatOpt(w.current, "lbs"))")
        lines.append("7 days ago: \(formatOpt(w.sevenDaysAgo, "lbs"))")
        lines.append("30 days ago: \(formatOpt(w.thirtyDaysAgo, "lbs"))")
        lines.append("Trend: \(w.trend)")
        if let rate = w.weeklyChangeRate {
            lines.append("Weekly change rate: \(String(format: "%.1f", rate)) lbs/week")
        }
        lines.append("")

        // Mood
        let m = stats.moodStats
        lines.append("MOOD")
        if let mood = m.todayMood { lines.append("Today's mood: \(mood)/5") }
        if let avg = m.sevenDayAverageMood { lines.append("7-day average: \(String(format: "%.1f", avg))/5") }
        lines.append("Trend: \(m.moodTrend)")
        if let best = m.bestMoodDay { lines.append("Best mood day: \(best)") }
        lines.append("")

        // Journal
        if let journal = stats.latestJournalEntry {
            lines.append("JOURNAL")
            if let date = stats.journalDate { lines.append("Date: \(date)") }
            lines.append(journal)
            lines.append("")
        }

        // Goals
        lines.append("GOALS")
        for cat in stats.categoryStats {
            lines.append("")
            lines.append("\(cat.categoryName) Category (Level \(cat.level), \(cat.xp) XP):")
            lines.append("  Category streak: \(cat.currentStreak) days")
            for goal in cat.goalStats {
                lines.append("")
                lines.append("  Goal: \(goal.goalName)")
                lines.append("  Frequency: \(goal.frequency) | XP: \(goal.xpValue)")
                lines.append("  Streak: \(goal.currentStreak) days | Longest: \(goal.longestStreak) days")
                lines.append("  Days active: \(goal.daysActive) | Target date: \(goal.targetDate)")
                if let remaining = goal.daysRemaining {
                    lines.append("  Days remaining: \(remaining)")
                }
                lines.append("  Velocity this week: \(String(format: "%.1f", goal.velocityCurrentWeek)) (last week: \(String(format: "%.1f", goal.velocityPreviousWeek))) — \(goal.velocityTrend)")

                let sortedDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                let perfStr = sortedDays.compactMap { day -> String? in
                    guard let rate = goal.weekdayPerformance[day] else { return nil }
                    return "\(day.prefix(3)): \(Int(rate * 100))%"
                }.joined(separator: ", ")
                if !perfStr.isEmpty {
                    lines.append("  Weekday performance: \(perfStr)")
                }

                if !goal.subMetricStats.isEmpty {
                    lines.append("  Sub-metrics:")
                    for sm in goal.subMetricStats {
                        var parts: [String] = []
                        if let v = sm.today { parts.append("today=\(formatVal(v, sm.unit))") }
                        if let v = sm.sevenDayAverage { parts.append("avg7d=\(formatVal(v, sm.unit))") }
                        if let v = sm.thirtyDayAverage { parts.append("avg30d=\(formatVal(v, sm.unit))") }
                        if let v = sm.bestValue { parts.append("best=\(formatVal(v, sm.unit))") }
                        parts.append("trend=\(sm.trend)")
                        lines.append("    \(sm.name) [\(sm.type)]: \(parts.joined(separator: ", "))")
                    }
                }
            }
        }

        lines.append("")
        lines.append("""
        Please provide a daily wellness insight with this structure:

        QUOTE:
        [A stoic or stoic-adjacent quote fitting today's data. Rotate between Marcus Aurelius, Epictetus, Seneca, Cato, Hemingway, Churchill, Jocko Willink, and Naval Ravikant. Choose based on what resonates with the user's current situation.]

        REFLECTION:
        [2-3 sentences honestly reflecting on the journal entry if one exists, or on recent patterns if not. Be direct about what the data says.]

        PROGRESS RECAP:
        [Bullet points for each active category. Include velocity trend. Be specific with numbers.]

        WINS TODAY:
        [Acknowledge what was actually accomplished. No participation trophies — only real wins.]

        FOCUS AREAS:
        [2-3 specific things that need attention based on the data. Be direct.]

        YOUR MISSION TODAY:
        [3 specific, actionable tasks for today based on current goal progress and velocity. Make them concrete and achievable.]

        SUGGESTED ADJUSTMENT:
        [One suggested new goal, modified target, or dropped goal based on patterns. Frame as a question the user can accept or reject tomorrow.]

        PRACTICAL TIPS: [For each active category, suggest 2-3
        small specific actionable things the user could do today
        or this week to move the needle. Base these on their actual
        data patterns — not generic advice. Examples: specific foods
        to hit protein targets, specific times to work out based on
        their best performing days, sleep hygiene adjustments based
        on their trend.]
        """)

        return lines.joined(separator: "\n")
    }

    private static func buildCompactStats(stats: AppStats) -> String {
        let d = stats.dietStats
        let e = stats.exerciseStats
        let s = stats.sleepStats
        let w = stats.weightStats
        return """
        Level \(stats.globalLevel), \(stats.globalXP) XP. \
        Diet: \(formatOpt(d.todayCalories, "kcal today")), \(formatOpt(d.todayProtein, "g protein")). \
        Sleep last night: \(formatOpt(s.lastNight, "h")). \
        Weight: \(formatOpt(w.current, "lbs")). \
        Lifting \(e.liftingDaysThisWeek) days this week, cardio \(e.cardioDaysThisWeek) days.
        """
    }

    private static func callAPI(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userPrompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("ClaudeService: API error \(http.statusCode): \(body)")
            throw URLError(.badServerResponse)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return text
    }

    private static func formatOpt(_ value: Double?, _ unit: String) -> String {
        guard let value else { return "N/A" }
        return "\(String(format: "%.0f", value)) \(unit)"
    }

    private static func formatVal(_ value: Double, _ unit: String) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return unit.isEmpty ? formatted : "\(formatted)\(unit)"
    }
}
