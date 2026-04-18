import Foundation
import SwiftData

@Model
final class LiftingSet {
    var id: UUID
    var reps: Int
    var weightKg: Double
    var setNumber: Int
    var entry: LiftingEntry?

    init(
        id: UUID = UUID(),
        reps: Int,
        weightKg: Double,
        setNumber: Int
    ) {
        self.id = id
        self.reps = reps
        self.weightKg = weightKg
        self.setNumber = setNumber
    }
}
