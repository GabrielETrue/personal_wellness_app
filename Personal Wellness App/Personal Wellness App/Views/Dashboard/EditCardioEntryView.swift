import SwiftUI
import SwiftData

struct EditCardioEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: CardioEntry?
    @State private var cardioType = "Run"
    @State private var duration = ""
    @State private var avgPace = ""
    @State private var date = Date()

    private let cardioTypes = ["Run", "Bike", "Swim", "Row", "Hike", "Other"]

    private var canSave: Bool { (Double(duration) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Cardio") {
                            Picker("Type", selection: $cardioType) {
                                ForEach(cardioTypes, id: \.self) { Text($0).tag($0) }
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            Divider().background(AppTheme.backgroundSecondary)
                            HStack {
                                Text("Duration (min)").foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                TextField("0", text: $duration)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .tint(AppTheme.accentBlue)
                                    .frame(maxWidth: 80)
                            }
                            Divider().background(AppTheme.backgroundSecondary)
                            HStack {
                                Text("Avg Pace").foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                TextField("e.g. 8:30/mi", text: $avgPace)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .tint(AppTheme.accentBlue)
                            }
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
            .navigationTitle("Edit Cardio Entry")
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
        guard let logs = try? modelContext.fetch(FetchDescriptor<CardioEntry>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        cardioType = found.type
        duration = found.durationMinutes.formatted()
        avgPace = found.avgPace
        date = found.date
    }

    private func save() {
        guard let record else { return }
        record.type = cardioType
        record.durationMinutes = Double(duration) ?? record.durationMinutes
        record.avgPace = avgPace
        record.date = date
        do {
            try modelContext.save()
        } catch {
            print("EditCardioEntryView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
