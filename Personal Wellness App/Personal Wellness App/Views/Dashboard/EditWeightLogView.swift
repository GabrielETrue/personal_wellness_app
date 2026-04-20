import SwiftUI
import SwiftData

struct EditWeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: WeightLog?
    @State private var weight: Double = 150.0
    @State private var date = Date()

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
                                    .foregroundStyle(AppTheme.accentCyan)
                                    .frame(maxWidth: .infinity)

                                Stepper("", value: $weight, in: 50...500, step: 0.5)
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
            .navigationTitle("Edit Weight")
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
        guard let logs = try? modelContext.fetch(FetchDescriptor<WeightLog>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        weight = found.weightLbs
        date = found.date
    }

    private func save() {
        guard let record else { return }
        record.weightLbs = weight
        record.date = date
        do {
            try modelContext.save()
        } catch {
            print("EditWeightLogView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
