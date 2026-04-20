import SwiftUI
import SwiftData

struct WeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WeightLog.date, order: .reverse) private var weightLogs: [WeightLog]
    @Query private var players: [PlayerProfile]

    @State private var weight: Double = 150.0
    @State private var date = Date()
    @State private var showingGoalSetter = false
    @State private var pendingGoalWeight: Double = 150.0

    private var player: PlayerProfile? { players.first }
    private var lastLog: WeightLog? { weightLogs.first }
    private var startingLog: WeightLog? { weightLogs.last }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Weight") {
                            VStack(spacing: 16) {
                                Text("\(weight.formatted()) lbs")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)

                                Stepper(
                                    "Weight",
                                    value: $weight,
                                    in: 50...500,
                                    step: 0.5
                                )
                                .labelsHidden()
                                .foregroundStyle(AppTheme.textPrimary)
                            }
                            .padding(.vertical, 8)
                        }

                        if let last = lastLog {
                            FormCard(header: "Last Entry") {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Last logged: \(last.weightLbs.formatted()) lbs")
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text(last.date.formatted(.dateTime.month(.wide).day().year()))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    let diff = weight - last.weightLbs
                                    if diff != 0 {
                                        Text(diff > 0 ? "+\(diff.formatted()) lbs" : "\(diff.formatted()) lbs")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(diff > 0 ? AppTheme.warning : AppTheme.success)
                                    }
                                }
                            }
                        }

                        goalWeightSection

                        FormCard(header: "Details") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Weight", isEnabled: true) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear {
                if let last = weightLogs.first {
                    weight = last.weightLbs
                }
                pendingGoalWeight = weight
            }
        }
    }

    @ViewBuilder
    private var goalWeightSection: some View {
        if let p = player, let target = p.targetWeightLbs {
            FormCard(header: "Goal Weight") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Goal: \(target.formatted()) lbs")
                            .foregroundStyle(AppTheme.textPrimary)
                            .fontWeight(.semibold)
                        Spacer()
                        let diff = weight - target
                        let isClose = abs(diff) <= 5
                        Text(diff == 0 ? "On target!" : (diff > 0 ? "+\(diff.formatted()) lbs" : "\(diff.formatted()) lbs"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(isClose ? AppTheme.success : AppTheme.warning)
                    }

                    if let start = startingLog {
                        let startW = start.weightLbs
                        let totalChange = target - startW
                        let progressChange = weight - startW
                        let fraction: Double = totalChange == 0 ? 1.0 : min(max(progressChange / totalChange, 0), 1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.backgroundSecondary)
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.xpGradient)
                                    .frame(width: geo.size.width * fraction, height: 10)
                            }
                        }
                        .frame(height: 10)
                        HStack {
                            Text("\(startW.formatted()) lbs")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("\(target.formatted()) lbs")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Button("Change Goal Weight") {
                        pendingGoalWeight = target
                        showingGoalSetter = true
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }

                if showingGoalSetter {
                    Divider().background(AppTheme.backgroundSecondary)
                    Stepper("Goal: \(pendingGoalWeight.formatted()) lbs", value: $pendingGoalWeight, in: 50...500, step: 0.5)
                        .foregroundStyle(AppTheme.textPrimary)
                    Button("Save Goal") { saveGoalWeight() }
                        .foregroundStyle(AppTheme.accentCyan)
                }
            }
        } else if let p = player {
            FormCard(header: "Goal Weight") {
                if showingGoalSetter {
                    Stepper("Goal: \(pendingGoalWeight.formatted()) lbs", value: $pendingGoalWeight, in: 50...500, step: 0.5)
                        .foregroundStyle(AppTheme.textPrimary)
                    Button("Save Goal") { saveGoalWeight() }
                        .foregroundStyle(AppTheme.accentCyan)
                } else {
                    Button("+ Set Goal Weight") {
                        pendingGoalWeight = weight
                        showingGoalSetter = true
                    }
                    .foregroundStyle(AppTheme.accentBlue)
                }
            }
            .opacity(p.id == p.id ? 1 : 0)
        }
    }

    private func saveGoalWeight() {
        guard let p = player else { return }
        p.targetWeightLbs = pendingGoalWeight
        do {
            try modelContext.save()
        } catch {
            print("WeightLogView saveGoalWeight failed: \(error)")
        }
        showingGoalSetter = false
    }

    private func save() {
        let allLogs = (try? modelContext.fetch(FetchDescriptor<WeightLog>())) ?? []
        if let existing = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            existing.weightLbs = weight
        } else {
            let log = WeightLog(weightLbs: weight, date: date)
            modelContext.insert(log)
        }
        do {
            try modelContext.save()
        } catch {
            print("WeightLogView save failed: \(error)")
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WeightLog.self, PlayerProfile.self, configurations: config)
    let ctx = container.mainContext
    ctx.insert(WeightLog(weightLbs: 178.5, date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()))
    ctx.insert(WeightLog(weightLbs: 175.0, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()))
    let p = PlayerProfile()
    p.targetWeightLbs = 170.0
    ctx.insert(p)
    return WeightLogView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
