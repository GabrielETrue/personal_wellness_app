import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var body: String
    var date: Date
    var mood: Int

    init(
        id: UUID = UUID(),
        body: String,
        date: Date = Date(),
        mood: Int = 0
    ) {
        self.id = id
        self.body = body
        self.date = date
        self.mood = mood
    }
}
