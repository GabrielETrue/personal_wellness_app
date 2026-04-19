import Foundation
import SwiftData

@Model
final class SubMetric {
    var id: UUID
    var name: String
    var unit: String
    var targetValue: Double
    @Attribute var type: String = "numeric"   // "numeric" | "checklist"
    var goal: Goal?
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.subMetric)
    var logs: [LogEntry] = []

    var isChecklistItem: Bool { type == "checklist" }

    init(
        id: UUID = UUID(),
        name: String,
        unit: String = "",
        targetValue: Double = 0,
        type: String = "numeric"
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.targetValue = targetValue
        self.type = type
    }
}
