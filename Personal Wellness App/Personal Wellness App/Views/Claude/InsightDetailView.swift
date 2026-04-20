import SwiftUI
import SwiftData

struct InsightDetailView: View {
    let insight: AIInsight
    @Environment(\.modelContext) private var modelContext

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d 'at' h:mm a"
        return f.string(from: insight.date)
    }

    private var parsed: ParsedInsight {
        ParsedInsight.parse(insight.content)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date subtitle
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.bottom, 4)

                    if parsed.sections.isEmpty {
                        // Fallback: plain cleaned text
                        Text(ParsedInsight.cleanMarkdown(insight.content))
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(4)
                    } else {
                        ForEach(parsed.sections) { section in
                            SectionCardView(section: section)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Daily Insight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: insight.content) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.accentBlue)
                }
            }
        }
        .onAppear {
            guard !insight.hasBeenRead else { return }
            insight.hasBeenRead = true
            do {
                try modelContext.save()
            } catch {
                print("InsightDetailView: save hasBeenRead failed: \(error)")
            }
        }
    }
}

// MARK: - Section Card

private struct SectionCardView: View {
    let section: InsightSection

    private var bulletColor: Color {
        section.header == "FOCUS AREAS:" ? AppTheme.warning : AppTheme.accentBlue
    }

    private var usesBulletList: Bool {
        section.header == "YOUR MISSION TODAY:" ||
        section.header == "PROGRESS RECAP:" ||
        section.header == "FOCUS AREAS:"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.isQuote {
                quoteCard
            } else {
                standardCard
            }
        }
    }

    // MARK: Quote Card

    private var quoteCard: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.accentPurple)
                .frame(width: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16, bottomLeadingRadius: 16,
                        bottomTrailingRadius: 0, topTrailingRadius: 0
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                headerLabel

                Text(ParsedInsight.cleanMarkdown(section.content))
                    .font(.body)
                    .italic()
                    .foregroundStyle(AppTheme.accentCyan)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.backgroundCard)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 16, topTrailingRadius: 16
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accentPurple, lineWidth: 1.5)
        )
    }

    // MARK: Standard Card

    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerLabel

            if usesBulletList {
                bulletContent
            } else {
                Text(ParsedInsight.cleanMarkdown(section.content))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accentBlue.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: Header Label

    private var headerLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.header.replacingOccurrences(of: ":", with: "").uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.accentBlue)
                .kerning(1.2)

            Rectangle()
                .fill(AppTheme.accentBlue.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: Bullet Content

    private var bulletContent: some View {
        let cleaned = ParsedInsight.cleanMarkdown(section.content)
        let lines = cleaned.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("•") {
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(bulletColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(String(trimmed.dropFirst(1).trimmingCharacters(in: .whitespaces)))
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(trimmed)
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AIInsight.self, configurations: config)
    let insight = AIInsight(content: """
    QUOTE:
    "You have power over your mind — not outside events. Realize this, and you will find strength." — Marcus Aurelius

    REFLECTION:
    Your sleep has been inconsistent this week, averaging 6.2 hours against your **8-hour goal**. The data is clear: this is the lever that will move everything else. Fix it tonight.

    PROGRESS RECAP:
    - Diet: 2,100 kcal avg — on track, *protein trending up*
    - Exercise: 3 lifting sessions this week, strong
    - Sleep: 6.2h avg — below goal, declining trend

    WINS TODAY:
    Completed all 3 sets of bench press at 100kg — new PR.

    FOCUS AREAS:
    - Sleep: get to bed by 10 PM tonight
    - Protein: you're 20g short on average
    - Cardio: zero sessions this week

    YOUR MISSION TODAY:
    - Log today's meals before dinner
    - 20-minute walk after work
    - In bed by 10 PM, no exceptions

    SUGGESTED ADJUSTMENT:
    Should your sleep goal be moved from 8h to 7.5h given your current schedule? Review tomorrow.
    """)
    container.mainContext.insert(insight)
    return NavigationStack {
        InsightDetailView(insight: insight)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
