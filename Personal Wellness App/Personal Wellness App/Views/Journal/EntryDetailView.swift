import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let entry: JournalEntry

    @State private var isEditing = false
    @State private var editBody = ""
    @State private var editMood = 0

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            if isEditing {
                VStack(spacing: 0) {
                    MoodSelectorRow(selectedMood: $editMood)
                        .padding()
                        .background(AppTheme.backgroundCard)

                    Divider().background(AppTheme.backgroundSecondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $editBody)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accentBlue)
                            .frame(minHeight: 300)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        if editBody.isEmpty {
                            Text("What's on your mind?")
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                                .padding(.top, 16)
                                .padding(.leading, 17)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.backgroundPrimary)

                    GradientSaveButton(
                        title: "Save Changes",
                        isEnabled: !editBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) { saveEdits() }
                        .padding()
                        .background(AppTheme.backgroundSecondary)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let emoji = moodEmoji(entry.mood) {
                            Text(emoji)
                                .font(.largeTitle)
                        }
                        Text(entry.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        editBody = entry.body
                        editMood = entry.mood
                        isEditing = true
                    }
                    .foregroundStyle(AppTheme.accentBlue)
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
    .preferredColorScheme(.dark)
}
