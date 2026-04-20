import SwiftUI
import SwiftData

struct EditLiftingEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: LiftingEntry?
    @State private var exerciseName = ""
    @State private var date = Date()
    @State private var sets: [LiftingSet] = []
    @State private var showingAddSet = false
    @State private var pendingReps = 8
    @State private var pendingWeight = ""

    private var canSave: Bool {
        !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty && !sets.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Exercise") {
                            ThemedTextField("Exercise name", text: $exerciseName)
                            Divider().background(AppTheme.backgroundSecondary)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        FormCard(header: "Sets") {
                            ForEach(Array(sets.enumerated()), id: \.element.id) { index, liftSet in
                                HStack {
                                    Text("Set \(index + 1): \(liftSet.reps) reps @ \(liftSet.weightKg.formatted()) lbs")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        if let idx = sets.firstIndex(where: { $0.id == liftSet.id }) {
                                            let s = sets.remove(at: idx)
                                            modelContext.delete(s)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill").foregroundStyle(AppTheme.danger)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Divider().background(AppTheme.backgroundSecondary)
                            }

                            if showingAddSet {
                                Stepper("Reps: \(pendingReps)", value: $pendingReps, in: 1...50)
                                    .foregroundStyle(AppTheme.textPrimary)
                                HStack {
                                    Text("Weight (lbs)").foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    TextField("0", text: $pendingWeight)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tint(AppTheme.accentBlue)
                                        .frame(maxWidth: 80)
                                }
                                Button("Confirm Set") {
                                    guard let entry = record else { return }
                                    let s = LiftingSet(
                                        reps: pendingReps,
                                        weightKg: Double(pendingWeight) ?? 0,
                                        setNumber: sets.count + 1
                                    )
                                    modelContext.insert(s)
                                    s.entry = entry
                                    sets.append(s)
                                    pendingReps = 8; pendingWeight = ""
                                    showingAddSet = false
                                }
                                .foregroundStyle(AppTheme.accentCyan)
                            } else {
                                Button("+ Add Set") { showingAddSet = true }
                                    .foregroundStyle(AppTheme.accentBlue)
                            }
                        }

                        GradientSaveButton(title: "Save Changes", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Lifting Entry")
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
        guard let logs = try? modelContext.fetch(FetchDescriptor<LiftingEntry>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        exerciseName = found.exerciseName
        date = found.date
        sets = found.sets.sorted { $0.setNumber < $1.setNumber }
    }

    private func save() {
        guard let record else { return }
        record.exerciseName = exerciseName.trimmingCharacters(in: .whitespaces)
        record.date = date
        for (i, s) in sets.enumerated() { s.setNumber = i + 1 }
        do {
            try modelContext.save()
        } catch {
            print("EditLiftingEntryView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
