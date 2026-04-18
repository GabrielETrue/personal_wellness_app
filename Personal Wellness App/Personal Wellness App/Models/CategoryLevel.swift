import Foundation
import SwiftData

@Model
final class CategoryLevel {
    var id: UUID
    var name: String
    var icon: String
    var xp: Int
    var level: Int
    var player: PlayerProfile?
    @Relationship(deleteRule: .cascade, inverse: \LevelEvent.categoryLevel)
    var levelHistory: [LevelEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \Goal.category)
    var goals: [Goal] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        xp: Int = 0,
        level: Int = 1
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.xp = xp
        self.level = level
    }
}
