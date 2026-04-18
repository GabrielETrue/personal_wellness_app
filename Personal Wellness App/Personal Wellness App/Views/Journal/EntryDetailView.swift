import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let entry: JournalEntry

    @State private var isEditing = false
    @State private var editBody = ""
    @State private var editMood = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    MoodSelectorRow(selectedMood: $editMood)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $editBody)
                            .frame(minHeight: 300)
                            .padding(.horizontal, 4)
                        if editBody.isEmpty {
                            Text("What's on your mind?")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 9)
                                .allowsHitTesting(false)
                        }
                    }
                } else {
                    if let emoji = moodEmoji(entry.mood) {
                        Text(emoji)
                            .font(.largeTitle)
                    }
                    Text(entry.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdits() }
                        .disabled(editBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        editBody = entry.body
                        editMood = entry.mood
                        isEditing = true
                    }
                }
            }
        }
    }

    private func saveEdits() {
        entry.body = editBody.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = editMood
        try? modelContext.save()
        isEditing = false
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: JournalEntry.self, configurations: config)
    let entry = JournalEntry(body: "Had a really productive day. Finished the app feature I was working on and went for a long walk in the evening.", mood: 4)
    container.mainContext.insert(entry)
    return NavigationStack {
        EntryDetailView(entry: entry)
    }
    .modelContainer(container)
}
