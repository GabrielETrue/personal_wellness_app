import SwiftUI
import SwiftData

struct EditLogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: LogEntry?
    @State private var valueText = ""
    @State private var isChecked = false
    @State private var notes = ""
    @State private var date = Date()
    @State private var isChecklist = false
    @State private var metricName = ""
    @State private var unit = ""

    private var canSave: Bool {
        isChecklist || (Double(valueText) != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if !metricName.isEmpty {
                            FormCard(header: "Metric") {
                                HStack {
                                    Text(metricName).foregroundStyle(AppTheme.textSecondary)
                                    if !unit.isEmpty {
                                        Text("(\(unit))").foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                .font(.subheadline)
                            }
                        }

                        FormCard(header: "Value") {
                            if isChecklist {
                                Toggle("Completed", isOn: $isChecked)
                                    .tint(AppTheme.accentBlue)
                                    .foregroundStyle(AppTheme.textPrimary)
                            } else {
                                HStack {
                                    Text(unit.isEmpty ? "Value" : unit)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    TextField("0", text: $valueText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tint(AppTheme.accentBlue)
                                        .frame(maxWidth: 100)
                                }
                            }
                            Divider().background(AppTheme.backgroundSecondary)
                            ThemedTextField("Notes (optional)", text: $notes)
                            Divider().background(AppTheme.backgroundSecondary)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Changes", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Entry")
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
        guard let logs = try? modelContext.fetch(FetchDescriptor<LogEntry>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        date = found.date
        notes = found.notes
        if let metric = found.subMetric {
            metricName = metric.name
            unit = metric.unit
            isChecklist = metric.isChecklistItem
        }
        if isChecklist {
            isChecked = found.value >= 1.0
        } else {
            valueText = found.value.formatted()
        }
    }

    private func save() {
        guard let record else { return }
        if isChecklist {
            record.value = isChecked ? 1.0 : 0.0
        } else {
            record.value = Double(valueText) ?? record.value
        }
        record.notes = notes
        record.date = date
        do {
            try modelContext.save()
        } catch {
            print("EditLogEntryView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
