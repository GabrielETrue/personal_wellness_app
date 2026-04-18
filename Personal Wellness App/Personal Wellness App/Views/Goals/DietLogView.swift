import SwiftUI
import SwiftData

struct DietLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var date = Date()
    @State private var nutrientDrafts: [NutrientDraft] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Food Item") {
                    TextField("Food name", text: $name)
                    Stepper("Calories: \(Int(calories))", value: $calories, in: 0...5000, step: 50)
                    Stepper("Protein: \(Int(protein))g", value: $protein, in: 0...500, step: 5)
                }

                Section {
                    ForEach($nutrientDrafts) { $draft in
                        NutrientDraftRow(draft: $draft)
                    }
                    .onDelete { nutrientDrafts.remove(atOffsets: $0) }
                    Button("Add Custom Nutrient") {
                        nutrientDrafts.append(NutrientDraft())
                    }
                } header: {
                    Text("Custom Nutrients")
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let log = FoodLog(
            name: name.trimmingCharacters(in: .whitespaces),
            calories: calories,
            protein: protein,
            date: date
        )
        modelContext.insert(log)

        for draft in nutrientDrafts where !draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let nutrient = CustomNutrient(
                name: draft.name.trimmingCharacters(in: .whitespaces),
                unit: draft.unit,
                value: Double(draft.value) ?? 0
            )
            modelContext.insert(nutrient)
            nutrient.foodLog = log
        }

        try? modelContext.save()
        dismiss()
    }
}

struct NutrientDraft: Identifiable {
    let id = UUID()
    var name = ""
    var value = ""
    var unit = ""
}

private struct NutrientDraftRow: View {
    @Binding var draft: NutrientDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Nutrient name", text: $draft.name)
            HStack {
                TextField("Amount", text: $draft.value)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 80)
                TextField("Unit (e.g. mg, g)", text: $draft.unit)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FoodLog.self, CustomNutrient.self,
        configurations: config
    )
    return DietLogView()
        .modelContainer(container)
}
