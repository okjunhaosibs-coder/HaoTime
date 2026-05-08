import SwiftUI
import SwiftData

@main
struct HaoTimeWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Category.self, Session.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
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
                    dataVM.aggregateForWeek(containing: Date(),
                        context: sharedModelContainer.mainContext)
                    WatchConnectivityManager.shared.activate()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
