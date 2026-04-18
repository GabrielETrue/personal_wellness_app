import Foundation
import SwiftData

@Model
final class SubMetric {
    var id: UUID
    var name: String
    var unit: String
    var targetValue: Double
    var goal: Goal?
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.subMetric)
    var logs: [LogEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        unit: String,
        targetValue: Double
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.targetValue = targetValue
    }
}
