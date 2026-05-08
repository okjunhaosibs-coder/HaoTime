import SwiftUI
import SwiftData

@main
struct HaoTimeWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Category.self, Session.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            WatchMainView(dataVM: dataVM, timerVM: timerVM)
                .onAppear {
                    let ctx = sharedModelContainer.mainContext
                    let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
                    let existing = (try? ctx.fetch(descriptor)) ?? []
                    if existing.isEmpty {
                        for (index, preset) in Category.presets.enumerated() {
                            let cat = Category(
                                name: preset.name,
                                colorHex: preset.colorHex,
                                iconName: preset.iconName,
                                sortOrder: index
                            )
                            ctx.insert(cat)
                        }
                        try? ctx.save()
                    }
                    dataVM.fetchCategories(context: ctx)
                    dataVM.aggregateForWeek(containing: Date(),
                        context: ctx)
                    WatchConnectivityManager.shared.activate()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
