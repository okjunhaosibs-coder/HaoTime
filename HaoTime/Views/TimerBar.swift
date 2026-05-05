import SwiftUI
import SwiftData

struct TimerBar: View {
    let categories: [Category]
    @Bindable var timerVM: TimerViewModel
    var modelContext: ModelContext

    @State private var showManualAdd = false
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    CategoryButton(
                        category: category,
                        isActive: timerVM.activeSession?.category?.id == category.id,
                        action: {
                            timerVM.toggle(category: category, context: modelContext)
                        }
                    )
                }
            }

            Spacer()

            if let session = timerVM.activeSession, let cat = session.category {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: 8, height: 8)
                    Text(timerVM.elapsedString)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: cat.colorHex))
                    Text(cat.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("停止") {
                        timerVM.stop(context: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                }
            } else {
                Text("点击类别开始计时")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Menu {
                Button {
                    showManualAdd = true
                } label: {
                    Label("手动添加记录", systemImage: "plus.circle")
                }
                Button {
                    showSettings = true
                } label: {
                    Label("管理类别", systemImage: "slider.horizontal.3")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .alert("切换类别？", isPresented: $timerVM.isShowingSwitchAlert) {
            Button("取消", role: .cancel) { timerVM.cancelSwitch() }
            Button("切换并停止当前") { timerVM.confirmSwitch(context: modelContext) }
        } message: {
            if let pending = timerVM.pendingCategory, let active = timerVM.activeSession?.category {
                Text("停止「\(active.name)」并开始「\(pending.name)」？")
            }
        }
        .sheet(isPresented: $showManualAdd) {
            SessionEditView(context: modelContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(isActive ? 1.0 : 0.3))
                    .frame(width: 42, height: 42)

                Image(systemName: category.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(isActive ? .white : Color(hex: category.colorHex))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
