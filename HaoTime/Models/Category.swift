import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String = "circle.fill",
        sortOrder: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    static let presets: [(name: String, colorHex: String, iconName: String)] = [
        ("写作", "#B395BD", "pencil"),
        ("思考", "#4ECDC4", "brain"),
        ("杂事", "#FFD93D", "checklist"),
        ("运动", "#FF6B6B", "figure.run")
    ]
}
