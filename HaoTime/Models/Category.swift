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
    var builtInName: String? = nil
    @Relationship(deleteRule: .nullify, inverse: \Session.category)
    var sessions: [Session]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        colorHex: String = "#888888",
        iconName: String = "circle.fill",
        sortOrder: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        builtInName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.builtInName = builtInName
    }

    static let sportCategoryName = "运动"

    static let presetIDs: [String] = [
        "B0000000-0000-0000-0000-000000000010",
        "B0000000-0000-0000-0000-000000000011",
        "B0000000-0000-0000-0000-000000000012",
        "B0000000-0000-0000-0000-000000000013",
        "B0000000-0000-0000-0000-000000000014",
    ]

    static let presets: [(name: String, colorHex: String, iconName: String, builtInName: String?)] = [
        ("运动", "#FF6B6B", "figure.run", "运动"),
        ("写作", "#B395BD", "pencil", nil),
        ("思考", "#4ECDC4", "brain", nil),
        ("编程", "#FF8C00", "keyboard", nil),
        ("杂事", "#FFD93D", "checklist", nil),
    ]
}
