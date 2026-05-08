import SwiftUI
import SwiftData

struct WatchTimerView: View {
    let category: Category
    let timerVM: TimerViewModel
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        VStack(spacing: 12 * s) {
                Spacer()

                Image(systemName: category.iconName)
                    .font(.system(size: 20 * s))
                    .foregroundStyle(Color(hex: category.colorHex))

                Text(category.name)
                    .font(.system(size: 13 * s, weight: .medium))
                    .foregroundStyle(.primary)

                Text(timerVM.elapsedString)
                    .font(.system(size: 18 * s, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: category.colorHex))

                Spacer()

                Button {
                    timerVM.stop(context: modelContext)
                    onDismiss()
                } label: {
                    Text("STOP")
                        .font(.system(size: 13 * s, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60 * s, height: 60 * s)
                        .background(Circle().fill(.red))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden)
    }
}
