import SwiftUI

struct RingView: View {
    let segments: [(color: Color, proportion: CGFloat)]
    let size: CGFloat
    let lineWidth: CGFloat

    init(categoryDurations: [(color: Color, duration: TimeInterval)], size: CGFloat, lineWidth: CGFloat? = nil) {
        self.size = size
        self.lineWidth = lineWidth ?? size * 0.12
        let maxHours: CGFloat = 12.0
        let total = categoryDurations.reduce(0) { $0 + $1.duration }
        if total > 0 {
            var cumulative: CGFloat = 0
            var result: [(color: Color, proportion: CGFloat)] = []
            for item in categoryDurations {
                let prop = CGFloat(item.duration / TimeInterval(maxHours * 3600))
                result.append((item.color, prop))
                cumulative += prop
            }
            let scale = cumulative > 1.0 ? 1.0 / cumulative : 1.0
            self.segments = result.map { ($0.color, min($0.proportion * scale, 1.0)) }
        } else {
            self.segments = []
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)

            ForEach(0..<segments.count, id: \.self) { index in
                let startAngle = startAngle(for: index)
                let endAngle = endAngle(for: index)
                Arc(startAngle: startAngle, endAngle: endAngle)
                    .stroke(segments[index].color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }
        }
        .frame(width: size, height: size)
    }

    private func startAngle(for index: Int) -> Angle {
        var cumulative: CGFloat = 0
        for i in 0..<index {
            cumulative += segments[i].proportion
        }
        return Angle(degrees: Double(cumulative * 360 - 90))
    }

    private func endAngle(for index: Int) -> Angle {
        var cumulative: CGFloat = 0
        for i in 0...index {
            cumulative += segments[i].proportion
        }
        return Angle(degrees: Double(cumulative * 360 - 90))
    }
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center, radius: radius,
                     startAngle: startAngle, endAngle: endAngle,
                     clockwise: false)
        return path
    }
}
