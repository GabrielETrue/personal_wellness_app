import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showingNewEntry = false

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No journal entries yet.",
                    systemImage: "book",
                    description: Text("Tap + to write your first entry.")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry)) {
                            EntryRow(entry: entry)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingNewEntry = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewEntryView()
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }
}

private struct EntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(entry.body.components(separatedBy: .newlines).first ?? entry.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let emoji = moodEmoji(entry.mood) {
                Text(emoji)
                    .font(.title3)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
