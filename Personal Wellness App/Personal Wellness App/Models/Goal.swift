import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var name: String
    var frequency: String
    var isActive: Bool
    var xpValue: Int
    var createdDate: Date
    var category: CategoryLevel?
    @Relationship(deleteRule: .cascade, inverse: \SubMetric.goal)
    var subMetrics: [SubMetric] = []

    init(
        id: UUID = UUID(),
        name: String,
        frequency: String,
        isActive: Bool = true,
        xpValue: Int = 10,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.isActive = isActive
        self.xpValue = xpValue
        self.createdDate = createdDate
    }
}
