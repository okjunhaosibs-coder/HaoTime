import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID = UUID()
    var category: Category? = nil
    var startTime: Date = Date()
    var endTime: Date? = nil
    var createdAt: Date = Date()

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
