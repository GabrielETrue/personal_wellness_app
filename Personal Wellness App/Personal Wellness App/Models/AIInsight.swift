import Foundation
import SwiftData

@Model
final class AIInsight {
    var id: UUID
    var content: String
    var date: Date
    var hasBeenRead: Bool

    init(
        id: UUID = UUID(),
        content: String,
        date: Date = Date(),
        hasBeenRead: Bool = false
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.hasBeenRead = hasBeenRead
    }
}
