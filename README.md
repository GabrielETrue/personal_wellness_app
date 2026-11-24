# Personal Wellness App

An iOS personal wellness app built with SwiftUI and SwiftData. Intended for personal use only — not App Store distribution.

## Features

### Goals & Metrics Tracker
- Log diet, exercise, sleep, and custom personalized goals
- Visual dashboards showing progress (daily, weekly, etc.)
- Gamification elements (streaks, XP, badges, level-ups) to drive motivation
- Quick log system for fast entry
- Goal creation wizard

### Claude AI Integration
- Write occasional journal entries
- Every night, Claude (via Anthropic API) reads the latest journal entry + current goal progress
- Generates a motivational summary with tips and goal suggestions
- Delivers this as a morning push notification
- Suggested new goals/metrics can be reviewed and accepted in-app

## Tech Stack

- **UI:** SwiftUI
- **Persistence:** SwiftData
- **AI:** Anthropic API (`claude-sonnet-4-6`)
- **Notifications:** UserNotifications framework

## Project Structure

```
Personal Wellness App/
├── Models/          # SwiftData model definitions
├── Views/
│   ├── Dashboard/   # Progress dashboards and category detail graphs
│   ├── Goals/       # Diet, exercise, sleep, and custom goal logging
│   ├── Journal/     # Journal entry creation and detail views
│   └── Shared/      # Reusable components (QuickLogView, LevelUpView, etc.)
└── Services/        # Business logic and API integrations
    ├── ClaudeService.swift
    ├── DashboardService.swift
    ├── GoalStatsService.swift
    ├── InsightGenerationService.swift
    ├── NotificationService.swift
    ├── AutoContributionService.swift
    ├── LevelUpService.swift
    ├── MarkdownParser.swift
    └── AppTheme.swift
```

## Build & Run

1. Open `Personal Wellness App/Personal Wellness App.xcodeproj` in Xcode
2. Add your Anthropic API key to `Services/Secrets.swift` (gitignored)
3. Select an iPhone simulator and press ⌘R

```bash
xcodebuild -project "Personal Wellness App/Personal Wellness App.xcodeproj" \
  -scheme "Personal Wellness App" \
  -destination "platform=iOS Simulator,name=iPhone 16" build
```

## Notes

- All units are imperial (lbs, miles)
- API key must be stored in `Services/Secrets.swift` (gitignored — never commit it)
- Built with Claude Code
