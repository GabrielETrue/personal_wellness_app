import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var name: String
    var category: String
    var targetValue: Double
    var unit: String
    var frequency: String
    var startDate: Date
    var isActive: Bool
    @Relationship(deleteRule: .cascade, inverse: \MetricLog.goal)
    var logs: [MetricLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        targetValue: Double,
        unit: String,
        frequency: String,
        startDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.targetValue = targetValue
        self.unit = unit
        self.frequency = frequency
        self.startDate = startDate
        self.isActive = isActive
    }
}
