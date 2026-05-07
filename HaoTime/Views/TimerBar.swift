import SwiftUI
import SwiftData

struct TimerBar: View {
    let categories: [Category]
    @Bindable var timerVM: TimerViewModel
    var modelContext: ModelContext
    var onDataDidChange: (() -> Void)?

    @State private var showManualAdd = false
    @State private var showSettings = false
    @Namespace private var animationNamespace
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutScale) private var layoutScale

    private var isCompact: Bool {
        #if os(iOS)
        true
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
        .onChange(of: showSettings) { _, showing in
            if !showing { onDataDidChange?() }
        }
    }

    // MARK: - Regular (Mac)

    private var regularLayout: some View {
        let s = layoutScale
        return HStack(spacing: 12 * s) {
            categoryButtons(size: 42 * s)
            Spacer()
            timerStatusSection
            Spacer()
            menuButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8 * s)
        .background(.ultraThinMaterial)
        .modifier(TimerBarModifiers(
            timerVM: timerVM,
            modelContext: modelContext,
            showManualAdd: $showManualAdd,
            showSettings: $showSettings
        ))
    }

    // MARK: - Compact (iPhone) with animation

    private var compactLayout: some View {
        let s = layoutScale
        return HStack(spacing: 4 * s) {
            if timerVM.isRunning, let session = timerVM.activeSession, let cat = session.category {
                // Timing state: icon - name - timer - stop
                Spacer()

                activeCategoryButton(cat, size: 44 * s)

                Text(cat.name)
                    .font(.system(size: 14 * s, weight: .medium))
                    .foregroundStyle(Color(hex: cat.colorHex))
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

                Text(timerVM.elapsedString)
                    .font(.system(size: 15 * s, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: cat.colorHex))
                    .fixedSize()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

                Button {
                    timerVM.stop(context: modelContext)
                } label: {
                    HStack(spacing: 2 * s) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 8 * s))
                        Text("停止")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.mini)
                .transition(.scale.combined(with: .opacity))

                Spacer()
                menuButton
            } else {
                // Idle state: all category buttons
                categoryButtons(size: 30 * s)
                Spacer(minLength: 2 * s)
                timerStatusSection
                    .offset(x: -8 * s)
                menuButton
            }
        }
        .padding(.horizontal, 8 * s)
        .padding(.vertical, 6 * s)
        .frame(height: 48 * s)
        .background(Color.black.opacity(0.05))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerVM.isRunning)
        .modifier(TimerBarModifiers(
            timerVM: timerVM,
            modelContext: modelContext,
            showManualAdd: $showManualAdd,
            showSettings: $showSettings
        ))
    }

    private func activeCategoryButton(_ category: Category, size: CGFloat) -> some View {
        Button {
            timerVM.stop(context: modelContext)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: size, height: size)
                Image(systemName: category.iconName)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: category.id, in: animationNamespace)
    }

    // MARK: - Shared Views

    private func categoryButtons(size: CGFloat) -> some View {
        HStack(spacing: size > 40 ? 8 : 6) {
            ForEach(categories) { category in
                CategoryButton(
                    category: category,
                    isActive: timerVM.activeSession?.category?.id == category.id,
                    size: size,
                    namespace: animationNamespace,
                    action: {
                        timerVM.toggle(category: category, context: modelContext)
                    }
                )
            }
        }
    }

    private var timerStatusSection: some View {
        let s = layoutScale
        return Group {
            if let session = timerVM.activeSession, let cat = session.category {
                HStack(spacing: 3 * s) {
                    Circle()
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: 5 * s, height: 5 * s)
                    Text(timerVM.elapsedString)
                        .font(.system(size: (isCompact ? 14 : 19) * s, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: cat.colorHex))
                        .fixedSize()
                    Text(cat.name)
                        .font(.system(size: 13 * s))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Button {
                        timerVM.stop(context: modelContext)
                    } label: {
                        HStack(spacing: 2 * s) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 8 * s))
                            Text("停止")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.mini)
                }
            } else {
                Text("点击类别开始计时")
                    .font(.system(size: 13 * s))
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

// MARK: - Modifiers

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
    var namespace: Namespace.ID
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
        .matchedGeometryEffect(id: category.id, in: namespace)
    }
}
