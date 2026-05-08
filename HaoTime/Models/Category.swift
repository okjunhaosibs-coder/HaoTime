import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#888888"
    var iconName: String = "circle.fill"
    var sortOrder: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()
    @Relationship(deleteRule: .nullify, inverse: \Session.category)
    var sessions: [Session]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        colorHex: String = "#888888",
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

    static let presetIDs: [String] = [
        "B0000000-0000-0000-0000-000000000001",
        "B0000000-0000-0000-0000-000000000002",
        "B0000000-0000-0000-0000-000000000003",
        "B0000000-0000-0000-0000-000000000004",
    ]

    static let presets: [(name: String, colorHex: String, iconName: String)] = [
        ("写作", "#B395BD", "pencil"),
        ("思考", "#4ECDC4", "brain"),
        ("杂事", "#FFD93D", "checklist"),
        ("运动", "#FF6B6B", "figure.run")
    ]
}
