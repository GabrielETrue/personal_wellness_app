import Foundation
import SwiftData

@Model
final class LiftingEntry {
    var id: UUID
    var date: Date
    var exerciseName: String
    @Relationship(deleteRule: .cascade, inverse: \LiftingSet.entry)
    var sets: [LiftingSet] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseName: String
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
    }
}
