import Foundation
import SwiftData

@Model
final class FoodLog {
    var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \CustomNutrient.foodLog)
    var customNutrients: [CustomNutrient] = []

    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.date = date
    }
}
