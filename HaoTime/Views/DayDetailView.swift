import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let ringSize: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ringSection
            barSection
        }
        .padding()
    }

    private var ringSection: some View {
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return (Color(hex: cat.colorHex), d)
        }
        return VStack(spacing: 8) {
            RingView(
                categoryDurations: durations,
                size: ringSize
            )
            let total = dataVM.totalDuration(for: date)
            Text(formatTotalHours(total))
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            Text("\(categories.filter { dataVM.duration(for: $0.id, on: date) > 0 }.count) 个类别有记录")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var barSection: some View {
        let items = categories.map { cat -> (name: String, color: Color, duration: TimeInterval) in
            (cat.name, Color(hex: cat.colorHex), dataVM.duration(for: cat.id, on: date))
        }
        return BarChartView(items: items)
    }

    private func formatTotalHours(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        return "\(h)h \(m)m"
    }
}
