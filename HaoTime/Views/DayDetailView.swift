import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let ringSize: CGFloat
    let context: ModelContext
    var centered: Bool = false
    var onCategoryTap: ((Category) -> Void)?
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        HStack(alignment: .center, spacing: 24 * s) {
            ringSection
            barSection
        }
        .frame(maxWidth: centered ? .infinity : nil)
        .padding(.horizontal, 20 * s)
        .padding(.vertical, 32 * s)
    }

    private var ringSection: some View {
        let s = layoutScale
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return (Color(hex: cat.colorHex), d)
        }
        let total = dataVM.totalDuration(for: date)

        return RingView(
            categoryDurations: durations,
            size: ringSize * s
        )
        .overlay {
            Text(formatTotalHours(total))
                .font(.system(size: 15 * s, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "#36494F"))
        }
    }

    private var barSection: some View {
        let items = categories.map { cat -> (id: UUID, name: String, color: Color, duration: TimeInterval) in
            (cat.id, cat.name, Color(hex: cat.colorHex), dataVM.duration(for: cat.id, on: date))
        }
        return BarChartView(items: items) { tappedName in
            if let cat = categories.first(where: { $0.name == tappedName }) {
                onCategoryTap?(cat)
            }
        }
    }

    private func formatTotalHours(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return "\(h)h \(m)m"
    }
}

#Preview("Day Detail - Today") {
    let context = PreviewHelpers.previewContainer.mainContext
    let vm = DataViewModel()
    vm.fetchCategories(context: context)
    vm.aggregateForWeek(containing: Date(), context: context)
    return DayDetailView(date: Date(), categories: vm.activeCategories, dataVM: vm, ringSize: 150, context: context)
        .frame(width: 600, height: 300)
}
