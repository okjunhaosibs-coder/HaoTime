import SwiftUI

struct BarChartView: View {
    let items: [(id: UUID, name: String, color: Color, duration: TimeInterval)]
    let maxHours: Double = 6.0
    var onTap: ((String) -> Void)?
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        let spacing = max(2, min(10, 40 / CGFloat(items.count))) * s
        VStack(spacing: spacing) {
            ForEach(items, id: \.id) { item in
                HStack(spacing: 8 * s) {
                    Text(item.name)
                        .font(.system(size: 13 * s))
                        .frame(width: 36 * s, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 22 * s)

                            if item.duration > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.color)
                                    .frame(
                                        width: min(geo.size.width, max(CGFloat(item.duration / (maxHours * 3600)) * geo.size.width, 4 * s)),
                                        height: 22 * s
                                    )
                            }
                        }
                    }
                    .frame(height: 22 * s)

                    Text(formatDuration(item.duration))
                        .font(.system(size: 12 * s, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 52 * s, alignment: .trailing)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?(item.name)
                }
            }
        }
        .padding(.horizontal, 8 * s)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration <= 0 { return "--" }
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

#Preview("Bar Chart - With Data") {
    BarChartView(items: [
        (UUID(), "写作", Color(hex: "#B395BD"), 7200),
        (UUID(), "思考", Color(hex: "#4ECDC4"), 5400),
        (UUID(), "杂事", Color(hex: "#FFD93D"), 0),
        (UUID(), "运动", Color(hex: "#FF6B6B"), 3600),
    ])
    .frame(width: 360)
    .padding()
}
