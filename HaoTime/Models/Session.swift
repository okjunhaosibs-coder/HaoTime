import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var category: Category?
    var startTime: Date
    var endTime: Date?
    var createdAt: Date

    var duration: TimeInterval {
        guard let endTime else { return Date().timeIntervalSince(startTime) }
        return endTime.timeIntervalSince(startTime)
    }

    var isActive: Bool { endTime == nil }

    init(
        id: UUID = UUID(),
        category: Category? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }
}
