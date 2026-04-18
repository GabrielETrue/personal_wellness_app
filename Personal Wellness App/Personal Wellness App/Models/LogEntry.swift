import Foundation
import SwiftData

@Model
final class LogEntry {
    var id: UUID
    var value: Double
    var date: Date
    var notes: String
    var subMetric: SubMetric?

    init(
        id: UUID = UUID(),
        value: Double,
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.value = value
        self.date = date
        self.notes = notes
    }
}
