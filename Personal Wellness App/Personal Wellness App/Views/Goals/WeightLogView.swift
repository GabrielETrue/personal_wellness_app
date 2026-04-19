import SwiftUI
import SwiftData

struct WeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WeightLog.date, order: .reverse) private var weightLogs: [WeightLog]

    @State private var weight: Double = 150.0
    @State private var date = Date()

    private var lastLog: WeightLog? { weightLogs.first }

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
            }
        }
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
    let container = try! ModelContainer(for: WeightLog.self, configurations: config)
    let ctx = container.mainContext
    ctx.insert(WeightLog(weightLbs: 178.5, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()))
    return WeightLogView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
