import SwiftUI
import SwiftData

struct EditFoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recordID: UUID
    let onSave: () -> Void

    @State private var record: FoodLog?
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var date = Date()
    @State private var customNutrients: [CustomNutrient] = []
    @State private var showingAddNutrient = false
    @State private var newNutrientName = ""
    @State private var newNutrientUnit = ""
    @State private var newNutrientValue = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(calories) ?? -1) >= 0 &&
        (Double(protein) ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormCard(header: "Food") {
                            ThemedTextField("Name", text: $name)
                            Divider().background(AppTheme.backgroundSecondary)
                            HStack {
                                Text("Calories").foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                TextField("0", text: $calories)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .tint(AppTheme.accentBlue)
                                    .frame(maxWidth: 100)
                            }
                            Divider().background(AppTheme.backgroundSecondary)
                            HStack {
                                Text("Protein (g)").foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                TextField("0", text: $protein)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .tint(AppTheme.accentBlue)
                                    .frame(maxWidth: 100)
                            }
                            Divider().background(AppTheme.backgroundSecondary)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .foregroundStyle(AppTheme.textPrimary)
                                .tint(AppTheme.accentBlue)
                        }

                        FormCard(header: "Custom Nutrients") {
                            ForEach(customNutrients) { nutrient in
                                HStack {
                                    Text("\(nutrient.name): \(nutrient.value.formatted()) \(nutrient.unit)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        if let idx = customNutrients.firstIndex(where: { $0.id == nutrient.id }) {
                                            let n = customNutrients.remove(at: idx)
                                            modelContext.delete(n)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill").foregroundStyle(AppTheme.danger)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Divider().background(AppTheme.backgroundSecondary)
                            }

                            if showingAddNutrient {
                                ThemedTextField("Nutrient name", text: $newNutrientName)
                                HStack {
                                    ThemedTextField("Unit", text: $newNutrientUnit)
                                    ThemedTextField("Amount", text: $newNutrientValue)
                                        .keyboardType(.decimalPad)
                                        .frame(maxWidth: 80)
                                }
                                .font(.subheadline)
                                Button("Confirm") {
                                    guard let val = Double(newNutrientValue),
                                          !newNutrientName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    let n = CustomNutrient(name: newNutrientName.trimmingCharacters(in: .whitespaces),
                                                           unit: newNutrientUnit,
                                                           value: val)
                                    modelContext.insert(n)
                                    n.foodLog = record
                                    customNutrients.append(n)
                                    newNutrientName = ""; newNutrientUnit = ""; newNutrientValue = ""
                                    showingAddNutrient = false
                                }
                                .foregroundStyle(AppTheme.accentCyan)
                            } else {
                                Button("+ Add Nutrient") { showingAddNutrient = true }
                                    .foregroundStyle(AppTheme.accentBlue)
                            }
                        }

                        GradientSaveButton(title: "Save Changes", isEnabled: canSave) { save() }
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Food Log")
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
        guard let logs = try? modelContext.fetch(FetchDescriptor<FoodLog>()),
              let found = logs.first(where: { $0.id == recordID }) else { return }
        record = found
        name = found.name
        calories = found.calories.formatted()
        protein = found.protein.formatted()
        date = found.date
        customNutrients = found.customNutrients.sorted { $0.name < $1.name }
    }

    private func save() {
        guard let record else { return }
        record.name = name.trimmingCharacters(in: .whitespaces)
        record.calories = Double(calories) ?? record.calories
        record.protein = Double(protein) ?? record.protein
        record.date = date
        do {
            try modelContext.save()
        } catch {
            print("EditFoodLogView save failed: \(error)")
        }
        onSave()
        dismiss()
    }
}
