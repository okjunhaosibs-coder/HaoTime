import Foundation
import SwiftData

enum PreviewHelpers {
    @MainActor
    static var previewContainer: ModelContainer = {
        let schema = Schema([Category.self, Session.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let cat1 = Category(name: "写作", colorHex: "#B395BD", iconName: "pencil", sortOrder: 0)
        let cat2 = Category(name: "思考", colorHex: "#4ECDC4", iconName: "brain", sortOrder: 1)
        let cat3 = Category(name: "杂事", colorHex: "#FFD93D", iconName: "checklist", sortOrder: 2)
        let cat4 = Category(name: "运动", colorHex: "#FF6B6B", iconName: "figure.run", sortOrder: 3)

        container.mainContext.insert(cat1)
        container.mainContext.insert(cat2)
        container.mainContext.insert(cat3)
        container.mainContext.insert(cat4)

        // Add some sample sessions
        let now = Date()
        let s1 = Session(category: cat1, startTime: now.addingTimeInterval(-7200), endTime: now.addingTimeInterval(-1800))
        let s2 = Session(category: cat2, startTime: now.addingTimeInterval(-5400), endTime: now.addingTimeInterval(-3600))
        let s3 = Session(category: cat4, startTime: now.addingTimeInterval(-3600), endTime: now.addingTimeInterval(-2700))

        container.mainContext.insert(s1)
        container.mainContext.insert(s2)
        container.mainContext.insert(s3)

        return container
    }()
}
