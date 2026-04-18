import Foundation
import SwiftData

@Model
final class SleepLog {
    var id: UUID
    var hoursSlept: Double
    var date: Date

    init(
        id: UUID = UUID(),
        hoursSlept: Double,
        date: Date = Date()
    ) {
        self.id = id
        self.hoursSlept = hoursSlept
        self.date = date
    }
}
