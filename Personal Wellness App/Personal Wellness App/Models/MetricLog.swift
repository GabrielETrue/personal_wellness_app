import Foundation
import SwiftData

@Model
final class MetricLog {
    var id: UUID
    var value: Double
    var date: Date
    var notes: String?
    var goal: Goal?

    init(
        id: UUID = UUID(),
        value: Double,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.value = value
        self.date = date
        self.notes = notes
    }
}
