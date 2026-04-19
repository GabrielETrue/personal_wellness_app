import SwiftUI
import SwiftData

struct SleepLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var hours: Double = 8.0
    @State private var date = Date()

    private let goalHours: Double = 8.0

    private var progress: Double { min(hours / goalHours, 1.0) }

    private var progressColor: Color {
        if hours >= 8 { return AppTheme.success }
        if hours >= 6 { return AppTheme.warning }
        return AppTheme.danger
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Hours Slept") {
                            VStack(spacing: 16) {
                                Text("\(hours.formatted()) hrs")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)

                                Stepper(
                                    "Hours slept",
                                    value: $hours,
                                    in: 0...14,
                                    step: 0.5
                                )
                                .labelsHidden()
                                .foregroundStyle(AppTheme.textPrimary)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Goal: \(goalHours.formatted()) hrs")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                        Spacer()
                                        Text(hours >= goalHours ? "Goal met ✓" : "\((goalHours - hours).formatted()) hrs short")
                                            .font(.caption)
                                            .foregroundStyle(hours >= goalHours ? AppTheme.success : AppTheme.textSecondary)
                                    }
                                    GradientProgressBar(value: progress, height: 8, tintColor: progressColor)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        FormCard(header: "Details") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Sleep Log", isEnabled: hours > 0) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func save() {
        let allLogs = (try? modelContext.fetch(FetchDescriptor<SleepLog>())) ?? []
        if let existing = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            existing.hoursSlept = hours
        } else {
            let log = SleepLog(hoursSlept: hours, date: date)
            modelContext.insert(log)
        }
        do {
            try modelContext.save()
        } catch {
            print("SleepLogView save failed: \(error)")
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    return SleepLogView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
