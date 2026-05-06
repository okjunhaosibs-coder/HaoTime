import SwiftUI

struct BarChartView: View {
    let items: [(name: String, color: Color, duration: TimeInterval)]
    let maxHours: Double = 12.0
    var onTap: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.name) { item in
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13))
                        .frame(width: 36, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 22)

                            if item.duration > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.color)
                                    .frame(
                                        width: max(CGFloat(item.duration / (maxHours * 3600)) * geo.size.width, 4),
                                        height: 22
                                    )
                            }
                        }
                    }
                    .frame(height: 22)

                    Text(formatDuration(item.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?(item.name)
                }
            }
        }
        .padding(.horizontal, 8)
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
        ("写作", Color(hex: "#B395BD"), 7200),
        ("思考", Color(hex: "#4ECDC4"), 5400),
        ("杂事", Color(hex: "#FFD93D"), 0),
        ("运动", Color(hex: "#FF6B6B"), 3600),
    ])
    .frame(width: 360)
    .padding()
}
