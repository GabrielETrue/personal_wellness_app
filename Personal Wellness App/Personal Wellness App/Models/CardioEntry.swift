import Foundation
import SwiftData

@Model
final class CardioEntry {
    var id: UUID
    var date: Date
    var type: String
    var durationMinutes: Double
    var avgPace: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: String,
        durationMinutes: Double,
        avgPace: String = ""
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.durationMinutes = durationMinutes
        self.avgPace = avgPace
    }
}
