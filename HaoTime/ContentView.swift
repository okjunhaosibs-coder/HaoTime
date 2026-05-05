import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        WeekView()
        #else
        ListView()
        #endif
    }
}
