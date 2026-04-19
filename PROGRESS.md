# Development Progress

## Completed
- Full SwiftData model layer (PlayerProfile, CategoryLevel, Goal,
  SubMetric, LogEntry, FoodLog, LiftingEntry, LiftingSet,
  CardioEntry, SleepLog, JournalEntry, AIInsight, LevelEvent)
- Seed data on first launch (PlayerProfile + 4 CategoryLevels)
- Goals tab: list by category, add goal with sub-metrics,
  log progress, XP awarding, level up detection, delete goals
- Journal tab: create entries with mood (emoji 1-5),
  view list, edit entries
- Dashboard tab: player header with global XP/level,
  category cards with streaks + today status,
  category detail on tap, filtered recent activity feed
- Specialized logging: DietLogView, ExerciseLogView, SleepLogView
- Full dark navy aesthetic with neon blue/purple accents (AppTheme)
- App runs on physical iPhone via Xcode direct install

## Design Decisions Made
- XP formula: xpForLevel(n) = 100 * n
- Global level + per-category levels both tracked
- Lifting: day-scoped (all sets for an exercise on same day
  grouped under one LiftingEntry)
- Sleep: standalone SleepLog, not through SubMetric system
- Tab structure: Dashboard, Goals, Journal, Claude (4 tabs)
- Color palette defined in Services/AppTheme.swift

## Remaining Features
- [ ] Claude AI integration (Anthropic API)
  - Nightly summary generation reading journal + goals
  - Morning push notification with summary
  - Goal suggestions from Claude (accept/reject flow)
  - API key stored securely, never committed to git
- [ ] Level up celebration screen (triggered when level threshold crossed)
- [ ] Diet-specific goal tracking (auto-roll FoodLog into Diet goals)
- [ ] Exercise-specific goal tracking (auto-roll lifting/cardio into Exercise goals)  
- [ ] Sleep-specific goal tracking (auto-roll SleepLog into Sleep goals)
- [ ] Widget (home screen quick-log) — requires WidgetKit extension
- [ ] App icon
- [ ] Polish pass after AI integration

## Known Issues / Deferred
- Widget deferred until after AI integration complete
- XP suggestions from Claude deferred until AI tab built
- Food/exercise/sleep logs don't yet auto-contribute to 
  goal SubMetric progress (manual LogEntry still required)

## Tech Stack
- SwiftUI + SwiftData
- iOS 18.2 target
- Anthropic API (claude-sonnet-4-20250514) — not yet integrated
- No third party dependencies