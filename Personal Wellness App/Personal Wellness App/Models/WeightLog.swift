import Foundation
import SwiftData

@Model
final class WeightLog {
    var id: UUID
    var weightLbs: Double
    var date: Date

    init(id: UUID = UUID(), weightLbs: Double, date: Date = Date()) {
        self.id = id
        self.weightLbs = weightLbs
        self.date = date
    }
}
