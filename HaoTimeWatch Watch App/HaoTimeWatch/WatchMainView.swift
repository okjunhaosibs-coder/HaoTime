import SwiftUI
import SwiftData

struct WatchMainView: View {
    let dataVM: DataViewModel
    let timerVM: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutScale) private var layoutScale
    @State private var selectedCategory: Category?
    @State private var ringDurations: [UUID: TimeInterval] = [:]
    @State private var ringTotal: TimeInterval = 0

    var body: some View {
        let s = layoutScale
        GeometryReader { geo in
            let ringSize = min(geo.size.height * 0.8, 100)
            HStack(spacing: 8 * s) {
                ringSection(size: ringSize)
                    .offset(x: -5 * s)

                VStack(alignment: .leading, spacing: max(4, 10 * s)) {
                    ForEach(dataVM.activeCategories) { cat in
                        categoryRow(cat)
                    }
                }
                .offset(x: 10 * s)
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
            WatchConnectivityManager.shared.onRemoteStart = { [timerVM] categoryID, startTime in
                if timerVM.isRunning {
                    timerVM.handleRemoteStop(context: modelContext)
                }
                timerVM.handleRemoteStart(categoryID: categoryID, startTime: startTime, context: modelContext)
                if let uuid = UUID(uuidString: categoryID),
                   let cat = dataVM.activeCategories.first(where: { $0.id == uuid }) {
                    selectedCategory = cat
                }
            }
            WatchConnectivityManager.shared.onRemoteStop = { [timerVM] in
                timerVM.handleRemoteStop(context: modelContext)
                selectedCategory = nil
            }
            WatchConnectivityManager.shared.activate()
            WatchConnectivityManager.shared.onRingData = { [self] durations, total, names in
                var mapped: [UUID: TimeInterval] = [:]
                for (key, val) in durations {
                    if let uuid = UUID(uuidString: key) { mapped[uuid] = val }
                }
                ringDurations = mapped
                ringTotal = total
                let ctx = modelContext
                for (key, name) in names {
                    if let uuid = UUID(uuidString: key) {
                        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == uuid })
                        if let cat = (try? ctx.fetch(descriptor))?.first, cat.name != name {
                            cat.name = name
                        }
                    }
                }
                try? ctx.save()
                dataVM.fetchCategories(context: ctx)
            }
        }
    }

    private func ringSection(size: CGFloat) -> some View {
        let s = layoutScale
        let durations = dataVM.activeCategories.compactMap { cat -> (Color, TimeInterval)? in
            let d = ringDurations[cat.id] ?? 0
            return d > 0 ? (Color(hex: cat.colorHex), d) : nil
        }

        return RingView(categoryDurations: durations, size: size)
            .overlay {
                Text(formatTotal(ringTotal))
                    .font(.system(size: 20 * s, design: .rounded))
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
                    .font(.system(size: 20 * s))
                    .foregroundStyle(Color(hex: cat.colorHex))
                    .frame(width: 28 * s)

                Text(cat.name)
                    .font(.system(size: 18 * s))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatTotal(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        return "\(h)h \(m)m"
    }
}
