import SwiftUI
import SwiftData

struct WatchMainView: View {
    let dataVM: DataViewModel
    let timerVM: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutScale) private var layoutScale
    @State private var selectedCategory: Category?

    var body: some View {
        let s = layoutScale
        GeometryReader { geo in
            let ringSize = min(geo.size.height * 0.5, 58)
            HStack(spacing: 8 * s) {
                ringSection(size: ringSize)

                VStack(alignment: .leading, spacing: max(4, 4 * s)) {
                    ForEach(dataVM.activeCategories) { cat in
                        categoryRow(cat)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(item: $selectedCategory) { category in
            WatchTimerView(
                category: category,
                timerVM: timerVM,
                onDismiss: {
                    selectedCategory = nil
                }
            )
        }
        .onAppear {
            WatchConnectivityManager.shared.onRemoteStop = { [timerVM] in
                timerVM.handleRemoteStop(context: modelContext)
                selectedCategory = nil
            }
        }
    }

    private func ringSection(size: CGFloat) -> some View {
        let s = layoutScale
        let durations = dataVM.activeCategories.compactMap { cat -> (Color, TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: Date())
            return d > 0 ? (Color(hex: cat.colorHex), d) : nil
        }
        let total = dataVM.totalDuration(for: Date())

        return RingView(categoryDurations: durations, size: size)
            .overlay {
                Text(formatTotal(total))
                    .font(.system(size: 8 * s, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
    }

    private func categoryRow(_ cat: Category) -> some View {
        let s = layoutScale
        return Button {
            timerVM.start(category: cat, context: modelContext)
            selectedCategory = cat
        } label: {
            HStack(spacing: max(3, 4 * s)) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(Color(hex: cat.colorHex))
                    .frame(width: 14 * s)

                Text(cat.name)
                    .font(.system(size: 10 * s))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatTotal(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }
}
