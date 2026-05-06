import SwiftUI
import SwiftData

@main
struct HaoTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Category.self, Session.self])
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }
}
