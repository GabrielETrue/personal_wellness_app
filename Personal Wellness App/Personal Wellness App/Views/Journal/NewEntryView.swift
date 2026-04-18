import SwiftUI
import SwiftData

struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var entryBody = ""
    @State private var selectedMood = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MoodSelectorRow(selectedMood: $selectedMood)
                    .padding()

                Divider()

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $entryBody)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    if entryBody.isEmpty {
                        Text("What's on your mind?")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 16)
                            .padding(.leading, 17)
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(entryBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}
