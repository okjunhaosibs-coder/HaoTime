import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let ringSize: CGFloat
    let context: ModelContext

    @State private var selectedCategory: Category?
    @State private var showCategorySessions = false

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ringSection
            barSection
        }
        .padding(.leading, 32)
        .padding(.trailing)
        .padding(.vertical, 32)
        .sheet(isPresented: $showCategorySessions) {
            if let cat = selectedCategory {
                CategorySessionsView(
                    date: date,
                    category: cat,
                    context: context
                )
            }
        }
    }

    private var ringSection: some View {
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return (Color(hex: cat.colorHex), d)
        }
        let total = dataVM.totalDuration(for: date)
        let activeCount = categories.filter { dataVM.duration(for: $0.id, on: date) > 0 }.count

        return RingView(
            categoryDurations: durations,
            size: ringSize
        )
        .overlay {
            VStack(spacing: 2) {
                Text(formatTotalHours(total))
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                Text("\(activeCount) 个类别有记录")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var barSection: some View {
        let items = categories.map { cat -> (name: String, color: Color, duration: TimeInterval) in
            (cat.name, Color(hex: cat.colorHex), dataVM.duration(for: cat.id, on: date))
        }
        return BarChartView(items: items) { tappedName in
            if let cat = categories.first(where: { $0.name == tappedName }) {
                selectedCategory = cat
                showCategorySessions = true
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
