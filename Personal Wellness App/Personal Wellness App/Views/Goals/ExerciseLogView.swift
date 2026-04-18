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
            Form {
                Section {
                    Picker("Type", selection: $exerciseType) {
                        Text("Lifting").tag("Lifting")
                        Text("Cardio").tag("Cardio")
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                if exerciseType == "Lifting" {
                    liftingSection
                } else {
                    cardioSection
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    // MARK: Lifting

    @ViewBuilder
    private var liftingSection: some View {
        Section("Exercise") {
            TextField("Exercise name (e.g. Bench Press)", text: $exerciseName)
        }

        Section {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, draft in
                Text("Set \(index + 1): \(draft.reps) reps @ \(draft.weightKg.formatted()) kg")
                    .font(.subheadline)
            }
            .onDelete { sets.remove(atOffsets: $0) }

            if showingAddSet {
                Stepper("Reps: \(pendingReps)", value: $pendingReps, in: 1...50)
                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("0", text: $pendingWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
                Button("Confirm Set") {
                    sets.append(SetDraft(reps: pendingReps, weightKg: Double(pendingWeight) ?? 0))
                    pendingReps = 8
                    pendingWeight = ""
                    showingAddSet = false
                }
                .foregroundStyle(.tint)
            } else {
                Button("Add Set") { showingAddSet = true }
                    .foregroundStyle(.tint)
            }
        } header: {
            Text("Sets")
        }
    }

    // MARK: Cardio

    @ViewBuilder
    private var cardioSection: some View {
        Section("Cardio") {
            Picker("Type", selection: $cardioType) {
                ForEach(cardioTypes, id: \.self) { Text($0).tag($0) }
            }
            HStack {
                Text("Duration (min)")
                Spacer()
                TextField("0", text: $cardioDuration)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Avg Pace")
                Spacer()
                TextField("e.g. 8:30/mi", text: $avgPace)
                    .multilineTextAlignment(.trailing)
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
}
