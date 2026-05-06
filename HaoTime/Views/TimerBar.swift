import SwiftUI
import SwiftData

struct TimerBar: View {
    let categories: [Category]
    @Bindable var timerVM: TimerViewModel
    var modelContext: ModelContext
    var onDataDidChange: (() -> Void)?

    @State private var showManualAdd = false
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        Group {
            if isCompact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .onChange(of: showManualAdd) { _, showing in
            if !showing { onDataDidChange?() }
        }
    }

    // MARK: - Regular (Mac)

    private var regularLayout: some View {
        HStack(spacing: 12) {
            categoryButtons(size: 42)
            Spacer()
            timerStatusSection
            Spacer()
            menuButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .modifier(TimerBarModifiers(
            timerVM: timerVM,
            modelContext: modelContext,
            showManualAdd: $showManualAdd,
            showSettings: $showSettings
        ))
    }

    // MARK: - Compact (iPhone)

    private var compactLayout: some View {
        HStack(spacing: 4) {
            categoryButtons(size: 30)
            Spacer(minLength: 2)
            timerStatusSection
                .offset(x: -8)
            menuButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .modifier(TimerBarModifiers(
            timerVM: timerVM,
            modelContext: modelContext,
            showManualAdd: $showManualAdd,
            showSettings: $showSettings
        ))
    }

    // MARK: - Shared Views

    private func categoryButtons(size: CGFloat) -> some View {
        HStack(spacing: size > 40 ? 8 : 6) {
            ForEach(categories) { category in
                CategoryButton(
                    category: category,
                    isActive: timerVM.activeSession?.category?.id == category.id,
                    size: size,
                    action: {
                        timerVM.toggle(category: category, context: modelContext)
                    }
                )
            }
        }
    }

    private var timerStatusSection: some View {
        Group {
            if let session = timerVM.activeSession, let cat = session.category {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: 5, height: 5)
                    Text(timerVM.elapsedString)
                        .font(.system(size: isCompact ? 14 : 19, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: cat.colorHex))
                        .fixedSize()
                    Text(cat.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Button {
                        timerVM.stop(context: modelContext)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 8))
                            Text("停止")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.mini)
                }
            } else {
                Text("点击类别开始计时")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var menuButton: some View {
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
                .font(.title2)
        }
        .menuStyle(.borderlessButton)
    }
}

// MARK: - Modifiers (shared between layouts)

struct TimerBarModifiers: ViewModifier {
    @Bindable var timerVM: TimerViewModel
    var modelContext: ModelContext
    @Binding var showManualAdd: Bool
    @Binding var showSettings: Bool

    func body(content: Content) -> some View {
        content
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

// MARK: - Category Button

struct CategoryButton: View {
    let category: Category
    let isActive: Bool
    var size: CGFloat = 42
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(isActive ? 1.0 : 0.3))
                    .frame(width: size, height: size)

                Image(systemName: category.iconName)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(isActive ? .white : Color(hex: category.colorHex))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Color Extension

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
