import SwiftUI
import SwiftData

struct EditSleepLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: SleepLog?
    @State private var hours: Double = 7.0
    @State private var date = Date()

    private var sleepColor: Color {
        switch hours {
        case ..<6:   return AppTheme.danger
        case 6..<7:  return AppTheme.warning
        case 7...9:  return AppTheme.accentCyan
        default:     return AppTheme.accentBlue
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Sleep") {
                            VStack(spacing: 16) {
                                Text("\(hours.formatted()) hrs")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                    .foregroundStyle(sleepColor)
                                    .frame(maxWidth: .infinity)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(AppTheme.backgroundSecondary)
                                            .frame(height: 8)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(sleepColor)
                                            .frame(width: geo.size.width * min(hours / 12.0, 1.0), height: 8)
                                    }
                                }
                                .frame(height: 8)

                                Stepper("", value: $hours, in: 0...24, step: 0.5)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 4)
                            Divider().background(AppTheme.backgroundSecondary)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Changes", isEnabled: true) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Sleep Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let logs = try? modelContext.fetch(FetchDescriptor<SleepLog>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        hours = found.hoursSlept
        date = found.date
    }

    private func save() {
        guard let record else { return }
        record.hoursSlept = hours
        record.date = date
        do {
            try modelContext.save()
        } catch {
            print("EditSleepLogView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
