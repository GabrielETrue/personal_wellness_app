import Foundation
import SwiftData

@Model
final class CustomNutrient {
    var id: UUID
    var name: String
    var unit: String
    var value: Double
    var foodLog: FoodLog?

    init(
        id: UUID = UUID(),
        name: String,
        unit: String,
        value: Double
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.value = value
    }
}
