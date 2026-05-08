import SwiftUI
import SwiftData

@main
struct HaoTimeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Category.self, Session.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var timerVM = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerVM)
                .onAppear {
                    WatchConnectivityManager.shared.activate()
                    setupWCSHandlers()
                }
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }

    @MainActor
    private func setupWCSHandlers() {
        let context = sharedModelContainer.mainContext
        WatchConnectivityManager.shared.onRemoteStart = { [weak timerVM] categoryID, startTime in
            timerVM?.handleRemoteStart(
                categoryID: categoryID,
                startTime: startTime,
                context: context
            )
        }
        WatchConnectivityManager.shared.onRemoteStop = { [weak timerVM] in
            timerVM?.handleRemoteStop(context: context)
        }
    }
}
