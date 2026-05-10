import SwiftUI
import SwiftData

struct DayColumn: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let isToday: Bool
    let isFuture: Bool
    let action: () -> Void
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        Button(action: action) {
            VStack(spacing: 6 * s) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                Text(dayNumber)
                    .font(.caption2)
                    .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))

                if isFuture {
                    Circle()
                        .stroke(Color.gray.opacity(0.08), lineWidth: 4 * s)
                        .frame(width: 44 * s, height: 44 * s)
                    Spacer().frame(height: CGFloat(categories.count) * 5 * s)
                    Text("--")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(height: 12 * s)
                } else {
                    ringPreview
                        .frame(width: 44 * s, height: 44 * s)

                    barPreview
                    totalText
                }
            }
            .padding(8 * s)
            .background(isToday ? Color.accentColor.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                isToday ?
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1) : nil
            )
        }
        .buttonStyle(.plain)
        .opacity(isFuture ? 0.35 : 1.0)
    }

    private var ringPreview: some View {
        let s = layoutScale
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return d > 0 ? (Color(hex: cat.colorHex), d) : nil
        }
        return RingView(categoryDurations: durations, size: 44 * s, lineWidth: 4 * s)
    }

    private var barPreview: some View {
        let s = layoutScale
        return VStack(spacing: 1 * s) {
            ForEach(categories) { cat in
                let d = dataVM.duration(for: cat.id, on: date)
                RoundedRectangle(cornerRadius: 1)
                    .fill(d > 0 ? Color(hex: cat.colorHex) : Color.clear)
                    .frame(
                        width: d > 0 ? min(56 * s, max(CGFloat(d / (6 * 3600)) * 56 * s, 4 * s)) : 0,
                        height: 4 * s
                    )
            }
        }
        .frame(height: CGFloat(categories.count) * 5 * s, alignment: .leading)
    }

    private var totalText: some View {
        let s = layoutScale
        let total = dataVM.totalDuration(for: date)
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        return Text(total > 0 ? "\(h)h \(m)m" : "--")
            .font(.system(size: 10 * s))
            .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
            .frame(height: 12 * s)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

#Preview("Day Column - Today") {
    let context = PreviewHelpers.previewContainer.mainContext
    let vm = DataViewModel()
    vm.fetchCategories(context: context)
    vm.aggregateForWeek(containing: Date(), context: context)
    return DayColumn(date: Date(), categories: vm.activeCategories, dataVM: vm, isToday: true, isFuture: false, action: {})
        .frame(width: 120, height: 180)
}

#Preview("Day Column - Future") {
    let context = PreviewHelpers.previewContainer.mainContext
    let vm = DataViewModel()
    vm.fetchCategories(context: context)
    let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    return DayColumn(date: futureDate, categories: vm.activeCategories, dataVM: vm, isToday: false, isFuture: true, action: {})
        .frame(width: 120, height: 180)
}
