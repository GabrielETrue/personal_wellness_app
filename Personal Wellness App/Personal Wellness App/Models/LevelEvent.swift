import Foundation
import SwiftData

@Model
final class LevelEvent {
    var id: UUID
    var level: Int
    var achievedDate: Date
    var categoryLevel: CategoryLevel?

    init(
        id: UUID = UUID(),
        level: Int,
        achievedDate: Date = Date()
    ) {
        self.id = id
        self.level = level
        self.achievedDate = achievedDate
    }
}
