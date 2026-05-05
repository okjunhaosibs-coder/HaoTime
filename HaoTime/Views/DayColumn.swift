import SwiftUI

struct DayColumn: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let isToday: Bool
    let isFuture: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                Text(dayNumber)
                    .font(.caption2)
                    .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))

                if isFuture {
                    Circle()
                        .stroke(Color.gray.opacity(0.08), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    Text("--")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ringPreview
                        .frame(width: 44, height: 44)

                    barPreview
                    totalText
                }
            }
            .padding(8)
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
        let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: date)
            return d > 0 ? (Color(hex: cat.colorHex), d) : nil
        }
        return RingView(categoryDurations: durations, size: 44, lineWidth: 4)
    }

    private var barPreview: some View {
        VStack(spacing: 1) {
            ForEach(categories) { cat in
                let d = dataVM.duration(for: cat.id, on: date)
                if d > 0 {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: cat.colorHex))
                        .frame(
                            width: max(CGFloat(d / (12 * 3600)) * 56, 4),
                            height: 4
                        )
                }
            }
        }
        .frame(height: CGFloat(categories.count * 5), alignment: .leading)
    }

    private var totalText: some View {
        let total = dataVM.totalDuration(for: date)
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        return Text(total > 0 ? "\(h)h \(m)m" : "--")
            .font(.system(size: 10))
            .foregroundStyle(isToday ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
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
