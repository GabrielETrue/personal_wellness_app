import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var exerciseType = "Lifting"
    @State private var date = Date()

    // Lifting state
    @State private var exerciseName = ""
    @State private var sets: [SetDraft] = []
    @State private var showingAddSet = false
    @State private var pendingReps = 8
    @State private var pendingWeight = ""

    // Cardio state
    @State private var cardioType = "Run"
    @State private var cardioDuration = ""
    @State private var avgPace = ""

    private let cardioTypes = ["Run", "Bike", "Swim", "Row", "Hike", "Other"]

    private var canSave: Bool {
        if exerciseType == "Lifting" {
            return !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty && !sets.isEmpty
        } else {
            return (Double(cardioDuration) ?? 0) > 0
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Type") {
                            Picker("Type", selection: $exerciseType) {
                                Text("Lifting").tag("Lifting")
                                Text("Cardio").tag("Cardio")
                            }
                            .pickerStyle(.segmented)
                        }

                        if exerciseType == "Lifting" {
                            liftingCards
                        } else {
                            cardioCard
                        }

                        FormCard(header: "Details") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Exercise", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Exercise")
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

    // MARK: Lifting

    @ViewBuilder
    private var liftingCards: some View {
        FormCard(header: "Exercise") {
            ThemedTextField("Exercise name (e.g. Bench Press)", text: $exerciseName)
        }

        FormCard(header: "Sets") {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, draft in
                HStack {
                    Text("Set \(index + 1): \(draft.reps) reps @ \(draft.weightKg.formatted()) kg")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        sets.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(AppTheme.danger)
                    }
                    .buttonStyle(.plain)
                }
                Divider().background(AppTheme.backgroundSecondary)
            }

            if showingAddSet {
                Stepper("Reps: \(pendingReps)", value: $pendingReps, in: 1...50)
                    .foregroundStyle(AppTheme.textPrimary)
                HStack {
                    Text("Weight (kg)")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    TextField("0", text: $pendingWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(AppTheme.textPrimary)
                        .tint(AppTheme.accentBlue)
                        .frame(maxWidth: 80)
                }
                Button("Confirm Set") {
                    sets.append(SetDraft(reps: pendingReps, weightKg: Double(pendingWeight) ?? 0))
                    pendingReps = 8
                    pendingWeight = ""
                    showingAddSet = false
                }
                .foregroundStyle(AppTheme.accentCyan)
            } else {
                Button("+ Add Set") { showingAddSet = true }
                    .foregroundStyle(AppTheme.accentBlue)
            }
        }
    }

    // MARK: Cardio

    @ViewBuilder
    private var cardioCard: some View {
        FormCard(header: "Cardio") {
            Picker("Type", selection: $cardioType) {
                ForEach(cardioTypes, id: \.self) { Text($0).tag($0) }
            }
            .foregroundStyle(AppTheme.textPrimary)
            Divider().background(AppTheme.backgroundSecondary)
            HStack {
                Text("Duration (min)")
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                TextField("0", text: $cardioDuration)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(AppTheme.textPrimary)
                    .tint(AppTheme.accentBlue)
                    .frame(maxWidth: 80)
            }
            Divider().background(AppTheme.backgroundSecondary)
            HStack {
                Text("Avg Pace")
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                TextField("e.g. 8:30/mi", text: $avgPace)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(AppTheme.textPrimary)
                    .tint(AppTheme.accentBlue)
            }
        }
    }

    // MARK: Save

    private func save() {
        if exerciseType == "Lifting" {
            saveLifting()
        } else {
            saveCardio()
        }
    }

    private func saveLifting() {
        let name = exerciseName.trimmingCharacters(in: .whitespaces)
        let allEntries = (try? modelContext.fetch(FetchDescriptor<LiftingEntry>())) ?? []
        let existing = allEntries.first {
            $0.exerciseName.lowercased() == name.lowercased() &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }

        let entry: LiftingEntry
        if let existing {
            entry = existing
        } else {
            entry = LiftingEntry(date: date, exerciseName: name)
            modelContext.insert(entry)
        }

        let startNumber = entry.sets.count + 1
        for (index, draft) in sets.enumerated() {
            let liftSet = LiftingSet(
                reps: draft.reps,
                weightKg: draft.weightKg,
                setNumber: startNumber + index
            )
            modelContext.insert(liftSet)
            liftSet.entry = entry
        }

        try? modelContext.save()
        dismiss()
    }

    private func saveCardio() {
        let entry = CardioEntry(
            date: date,
            type: cardioType,
            durationMinutes: Double(cardioDuration) ?? 0,
            avgPace: avgPace
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

struct SetDraft: Identifiable {
    let id = UUID()
    var reps: Int = 8
    var weightKg: Double = 0
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: LiftingEntry.self, LiftingSet.self, CardioEntry.self,
        configurations: config
    )
    return ExerciseLogView()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
