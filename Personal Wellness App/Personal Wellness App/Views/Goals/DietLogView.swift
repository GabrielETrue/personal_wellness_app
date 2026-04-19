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

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Food Item") {
                            ThemedTextField("Food name", text: $name)
                            Divider().background(AppTheme.backgroundSecondary)
                            Stepper("Calories: \(Int(calories))", value: $calories, in: 0...5000, step: 50)
                                .foregroundStyle(AppTheme.textPrimary)
                            Divider().background(AppTheme.backgroundSecondary)
                            Stepper("Protein: \(Int(protein))g", value: $protein, in: 0...500, step: 5)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        FormCard(header: "Custom Nutrients") {
                            ForEach($nutrientDrafts) { $draft in
                                NutrientDraftRow(draft: $draft)
                                Divider().background(AppTheme.backgroundSecondary)
                            }
                            Button("+ Add Custom Nutrient") {
                                nutrientDrafts.append(NutrientDraft())
                            }
                            .foregroundStyle(AppTheme.accentBlue)
                        }

                        FormCard(header: "Details") {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        GradientSaveButton(title: "Save Food Log", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Food")
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

        do {
            try modelContext.save()
        } catch {
            print("DietLogView save failed: \(error)")
        }
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
            ThemedTextField("Nutrient name", text: $draft.name)
            HStack {
                ThemedTextField("Amount", text: $draft.value)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 80)
                ThemedTextField("Unit (e.g. mg, g)", text: $draft.unit)
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
        .preferredColorScheme(.dark)
}
