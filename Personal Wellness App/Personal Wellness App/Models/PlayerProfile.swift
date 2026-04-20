import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var id: UUID
    var globalXP: Int
    var globalLevel: Int
    @Attribute var targetWeightLbs: Double? = nil
    @Relationship(deleteRule: .cascade, inverse: \CategoryLevel.player)
    var categoryLevels: [CategoryLevel] = []

    init(
        id: UUID = UUID(),
        globalXP: Int = 0,
        globalLevel: Int = 1
    ) {
        self.id = id
        self.globalXP = globalXP
        self.globalLevel = globalLevel
    }
}
