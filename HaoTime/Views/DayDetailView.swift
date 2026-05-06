import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let ringSize: CGFloat
    let context: ModelContext
    var onCategoryTap: ((Category) -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ringSection
            barSection
        }
        .padding(.leading, 32)
        .padding(.trailing)
        .padding(.vertical, 32)
    }

    private var ringSection: some View {
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return (Color(hex: cat.colorHex), d)
        }
        let total = dataVM.totalDuration(for: date)

        return RingView(
            categoryDurations: durations,
            size: ringSize
        )
        .overlay {
            Text(formatTotalHours(total))
                .font(.system(size: 15, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "#36494F"))
        }
    }

    private var barSection: some View {
        let items = categories.map { cat -> (name: String, color: Color, duration: TimeInterval) in
            (cat.name, Color(hex: cat.colorHex), dataVM.duration(for: cat.id, on: date))
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
