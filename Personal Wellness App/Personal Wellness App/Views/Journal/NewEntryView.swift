import SwiftUI
import SwiftData

struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var entryBody = ""
    @State private var selectedMood = 0

    private var canSave: Bool {
        !entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    MoodSelectorRow(selectedMood: $selectedMood)
                        .padding()
                        .background(AppTheme.backgroundCard)

                    Divider().background(AppTheme.backgroundSecondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $entryBody)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accentBlue)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        if entryBody.isEmpty {
                            Text("What's on your mind?")
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                                .padding(.top, 16)
                                .padding(.leading, 17)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.backgroundPrimary)

                    GradientSaveButton(title: "Save Entry", isEnabled: canSave) { save() }
                        .padding()
                        .background(AppTheme.backgroundSecondary)
                }
            }
            .navigationTitle("New Entry")
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
        let entry = JournalEntry(
            body: entryBody.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: selectedMood
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NewEntryView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
        .preferredColorScheme(.dark)
}
