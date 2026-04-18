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
        if hours >= 8 { return .green }
        if hours >= 6 { return .yellow }
        return .red
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Text("\(hours.formatted()) hrs")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)

                        Stepper(
                            "Hours slept",
                            value: $hours,
                            in: 0...14,
                            step: 0.5
                        )
                        .labelsHidden()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Goal: \(goalHours.formatted()) hrs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(hours >= goalHours ? "Goal met ✓" : "\((goalHours - hours).formatted()) hrs short")
                                    .font(.caption)
                                    .foregroundStyle(hours >= goalHours ? .green : .secondary)
                            }
                            ProgressView(value: progress)
                                .tint(progressColor)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(hours == 0)
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
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    return SleepLogView()
        .modelContainer(container)
}
