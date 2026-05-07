import SwiftUI

struct LayoutScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var layoutScale: CGFloat {
        get { self[LayoutScaleKey.self] }
        set { self[LayoutScaleKey.self] = newValue }
    }
}

extension CGFloat {
    func scaled(by scale: CGFloat) -> CGFloat {
        self * scale
    }
}

extension Double {
    func scaled(by scale: CGFloat) -> CGFloat {
        CGFloat(self) * scale
    }
}
