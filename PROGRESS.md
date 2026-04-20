cat > PROGRESS.md << 'EOF'
# Development Progress

## Completed
- Full SwiftData model layer (PlayerProfile, CategoryLevel, Goal,
  SubMetric, LogEntry, FoodLog, LiftingEntry, LiftingSet,
  CardioEntry, SleepLog, JournalEntry, AIInsight, LevelEvent,
  WeightLog)
- Seed data on first launch (PlayerProfile + 4 CategoryLevels)
- Goals tab: list by category, add goal with sub-metrics,
  log progress, XP awarding, level up detection, delete goals
  checklist sub-metrics, optional target dates
- Journal tab: create entries with mood (emoji 1-5),
  view list, edit entries
- Dashboard tab: player header with global XP/level,
  category cards with streaks + today status,
  category detail on tap, filtered recent activity feed,
  time horizon picker on graphs, long press edit and delete
- Specialized logging: DietLogView, ExerciseLogView, SleepLogView
- Weight logging with WeightLogView accessible from Dashboard
- Swift Charts integration: diet, exercise, sleep, weight graphs
  with flexible time horizons (7D/1M/3M/6M/1Y/All)
- Full dark navy aesthetic with neon blue/purple accents (AppTheme)
- Claude AI integration:
  - Anthropic API connected (claude-sonnet-4-6)
  - GoalStatsService computing comprehensive stats
  - Full summary generation with stoic quotes
  - Quick push on demand
  - InsightDetailView with markdown parsing and section rendering
  - AIInsight history feed in Claude tab
  - Local notification scheduled at 4am
- Edit activity from Dashboard long press (all activity types)
- Imperial units throughout
- Efficient data fetching with bounded queries and sort descriptors
- Resilient ModelContainer with migration recovery
- App runs on physical iPhone via Xcode direct install

## Design Decisions Made
- XP formula: xpForLevel(n) = 100 * n
- Global level + per-category levels both tracked
- Lifting: day-scoped (all sets for an exercise on same day
  grouped under one LiftingEntry)
- Sleep: standalone SleepLog, not through SubMetric system
- Tab structure: Dashboard, Goals, Journal, Claude (4 tabs)
- Color palette defined in Services/AppTheme.swift
- SubMetric types: "numeric" or "checklist"
- Checklist items log value 1.0 to LogEntry on completion
- Model string: claude-sonnet-4-6
- API key stored in Secrets.swift (gitignored)
- Local notifications only (no remote push needed)
- Units: imperial throughout (lbs, miles, etc.)

## Remaining Features

### High Priority
- [ ] Goal weight target — add targetWeightLbs field to
      PlayerProfile or as a dedicated GoalWeight model.
      Show progress toward goal weight on Dashboard weight graph.
      WeightLogView should show distance from goal.

- [ ] Improved logging UX — current flow requires navigating
      into a specific goal to log progress. Need a faster path:
      Consider a floating "+" quick log button on Dashboard
      or a dedicated "Log Today" sheet accessible from anywhere
      that shows all active goals and lets you log against
      each one in a single session. Priority: high since
      this affects daily usage friction.

- [ ] Checklist sub-metric UX fix — AddGoalView currently
      shows a toggle for checklist type but does not show
      fields to add individual checklist items. Need to
      add an inline list of named checklist items when
      type is set to checklist, similar to how sub-metrics
      are added for numeric goals.

- [ ] Goal creation guidance — the current AddGoalView is
      confusing especially for Diet, Exercise, and Sleep
      categories. Need guided goal creation flows:
      Diet: pre-filled template with calories and protein
      targets, user just sets the numbers
      Exercise: pre-filled template with lifting days/week
      and cardio days/week targets
      Sleep: pre-filled template with hours target
      Custom: existing free-form flow is fine
      Consider a goal creation wizard with category-specific
      templates that pre-populate sub-metrics so the user
      just adjusts values rather than building from scratch.

- [ ] Claude prompt improvements — add to buildUserPrompt():
      A section asking Claude to suggest specific small
      actionable tips for each goal category based on
      current velocity and patterns. Examples: "Try meal
      prepping Sunday to hit protein targets" or "A 20 min
      walk at lunch would get you to your cardio goal."
      These should be concrete and based on the actual data.

### Medium Priority
- [ ] Level up celebration screen — triggered when
      categoryLevel.level or globalLevel increments.
      Full screen modal with animation, level badge,
      XP summary. Currently level ups are detected but
      no visual feedback is shown.

- [ ] Auto-contribution of specialized logs to goals —
      FoodLog calories/protein should automatically count
      toward Diet category SubMetric targets. LiftingEntry
      and CardioEntry should count toward Exercise goals.
      SleepLog should count toward Sleep goals. Currently
      these are separate systems.

- [ ] Background summary generation — true 4am auto-generation
      requires iOS Background App Refresh capability.
      Current setup schedules notification but requires
      manual generation. Implement BGTaskScheduler for
      nightly background fetch.

- [ ] Settings screen — place to view full player stats,
      manage API key, set goal weight, toggle notification
      time, clear test data.

### Low Priority / Future
- [ ] Home screen widget (WidgetKit) — requires App Groups
      setup in Xcode + WidgetKit extension target.
      Deferred until core features complete.
- [ ] App icon — generate 1024x1024 PNG and drop into
      Assets.xcassets AppIcon slot.
- [ ] XP suggestions from Claude during goal creation.
- [ ] Social/sharing features if desired later.

## Known Issues / Watch List
- Energy impact showed "High" in Xcode profiler — likely
  Swift Charts redrawing. Monitor on device during normal use.
- Background summary generation not yet implemented —
  user must manually generate summary each evening.
- weightKg field in LiftingSet is named kg but stores lbs
  (field rename would break SwiftData schema).

## Tech Stack
- SwiftUI + SwiftData
- iOS 18.2 target
- Anthropic API (claude-sonnet-4-6)
- Swift Charts (native)
- No third party dependencies
- Secrets.swift gitignored for API key
EOF