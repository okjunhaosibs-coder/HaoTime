import SwiftUI

struct BarChartView: View {
    let items: [(name: String, color: Color, duration: TimeInterval)]
    let maxHours: Double = 12.0

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
