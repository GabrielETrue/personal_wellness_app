# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project

iOS personal wellness app built with SwiftUI and SwiftData. Intended for personal use only — not App Store distribution.

## App Overview

Two core components:

### 1. Goals & Metrics Tracker
- Log diet, exercise, and custom personalized goals
- Visual dashboards showing progress (daily, weekly, etc.)
- Gamification elements (streaks, XP, badges) to drive motivation

### 2. Claude AI Integration
- User writes occasional journal entries
- Every night, Claude (via Anthropic API) reads the latest journal entry + current goal progress
- Generates a motivational summary with tips and goal suggestions
- Delivers this as a morning push notification
- Suggested new goals/metrics can be reviewed and accepted in-app

## Tech Stack

- **UI:** SwiftUI
- **Persistence:** SwiftData
- **AI:** Anthropic API (claude-sonnet-4-20250514)
- **Notifications:** UserNotifications framework

## Architecture

- `Personal_Wellness_AppApp.swift` — app entry point; sets up shared `ModelContainer`
- `Item.swift` — placeholder SwiftData model; to be replaced with real data models
- `ContentView.swift` — root view; to be replaced with proper navigation structure

All SwiftData `@Model` classes must be registered in the `Schema` array in `Personal_Wellness_AppApp.swift`.

Tests use Swift Testing (`import Testing`) with `@Test` functions and `#expect(...)` assertions.

## Build & Run

Open `Personal Wellness App/Personal Wellness App.xcodeproj` in Xcode, select an iPhone simulator, and press ⌘R.

```bash
# Build
xcodebuild -project "Personal Wellness App/Personal Wellness App.xcodeproj" -scheme "Personal Wellness App" -destination "platform=iOS Simulator,name=iPhone 16" build
```

## Development Guidelines

- Always use SwiftUI previews when creating new views
- Keep views small and composable — break large views into subviews
- Data models go in a `Models/` folder, views in `Views/`, and API/service logic in `Services/`
- Never hardcode the Anthropic API key — store it in a local config file that is gitignored
- When adding a new SwiftData model, immediately register it in the Schema in `Personal_Wellness_AppApp.swift`