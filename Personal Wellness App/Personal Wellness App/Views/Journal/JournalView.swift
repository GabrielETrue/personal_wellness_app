import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showingNewEntry = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

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
                            .listRowBackground(AppTheme.backgroundCard)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Journal")
        .toolbarBackground(AppTheme.backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingNewEntry = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppTheme.accentBlue)
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
        do {
            try modelContext.save()
        } catch {
            print("JournalView deleteEntries save failed: \(error)")
        }
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
                    .foregroundStyle(AppTheme.accentBlue)
                Text(entry.body.components(separatedBy: .newlines).first ?? entry.body)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
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
    .preferredColorScheme(.dark)
}
