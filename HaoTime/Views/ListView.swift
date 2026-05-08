import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataVM = DataViewModel()
    @Environment(TimerViewModel.self) private var timerVM
    @State private var selectedDate: Date?
    @State private var showDayDetail = false
    @State private var tappedCategory: Category?
    @State private var showCategorySessions = false
    @State private var weekStartDate: Date = WeekView.mondayOfWeek(containing: Date())

    var body: some View {
        GeometryReader { geo in
        let scale = min(max(geo.size.width / 390, 0.85), 1.2)
        VStack(spacing: 0) {
            TimerBar(
                categories: dataVM.activeCategories,
                timerVM: timerVM,
                modelContext: modelContext,
                onDataDidChange: { refreshData() }
            )

            todayDetail

            Divider()
                .padding(.horizontal)

            weekCards

            Text("左右滑动查看更多历史记录")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 20)
                .padding(.bottom, 8)
        }
        .environment(\.layoutScale, scale)
        .onAppear {
            dataVM.fetchCategories(context: modelContext)
            refreshData()
            resumeActiveSession()
        }
        .sheet(isPresented: $showDayDetail) {
            if let date = selectedDate {
                DaySessionsView(date: date, context: modelContext)
            }
        }
#if os(iOS)
        .sheet(isPresented: $showCategorySessions) {
            if let cat = tappedCategory {
                CategorySessionsView(
                    date: selectedDate ?? Date(),
                    category: cat,
                    context: modelContext
                )
            }
        }
#else
        .popover(isPresented: $showCategorySessions) {
            if let cat = tappedCategory {
                CategorySessionsView(
                    date: selectedDate ?? Date(),
                    category: cat,
                    context: modelContext
                )
            }
        }
#endif
        .onChange(of: showDayDetail) { _, newValue in
            if !newValue { refreshData() }
        }
        .onChange(of: showCategorySessions) { _, newValue in
            if !newValue { refreshData() }
        }
        .onChange(of: timerVM.isRunning) { _, running in
            if !running { refreshData() }
        }
        }
    }

    private var todayDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今天")
                    .font(.headline)
                Text(todayFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            DayDetailView(
                date: Date(),
                categories: dataVM.activeCategories,
                dataVM: dataVM,
                ringSize: 100,
                context: modelContext,
                centered: true,
                onCategoryTap: { cat in
                    tappedCategory = cat
                    selectedDate = Date()
                    showCategorySessions = true
                }
            )
        }
    }

    private let visibleWeekCount = 4
    @State private var currentWeekIndex = 3

    private var weekCards: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach(0..<visibleWeekCount, id: \.self) { displayIndex in
                let weekOffset = visibleWeekCount - 1 - displayIndex
                let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weekOffset, to: weekStartDate)!
                weekSection(starting: weekStart)
                    .tag(displayIndex)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .frame(height: 430)
        .padding(.top, 15)
    }

    private func weekSection(starting monday: Date) -> some View {
        let days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: monday) }
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: monday)!
        let isCurrentWeek = Calendar.current.isDate(monday, equalTo: weekStartDate, toGranularity: .weekOfYear)

        return ScrollView {
            VStack(spacing: 8) {
                HStack {
                    if isCurrentWeek {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                        Text("本周")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(weekRangeText(start: monday, end: endDate))
                        .font(.caption)
                        .foregroundStyle(isCurrentWeek ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))
                    Spacer()
                }
                .padding(.horizontal, 24)

                ForEach(days, id: \.self) { date in
                if date <= Date() {
                    DayCard(
                        date: date,
                        categories: dataVM.activeCategories,
                        dataVM: dataVM,
                        isToday: Calendar.current.isDateInToday(date)
                    )
                    .padding(.horizontal)
                    .onTapGesture {
                        selectedDate = date
                        showDayDetail = true
                    }
                } else {
                    FutureDayCard(date: date)
                        .padding(.horizontal)
                }
            }
            }
        }
    }

    private func weekRangeText(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return "\(f.string(from: start)) — \(f.string(from: end))"
    }

    private var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: Date())
    }

    private func refreshData() {
        dataVM.fetchCategories(context: modelContext)
        dataVM.aggregateForWeeks(weekCount: visibleWeekCount, endingOn: Date(), context: modelContext)
        #if os(iOS)
        Task { await dataVM.importTodayWorkouts(context: modelContext) }
        #endif
    }

    private func resumeActiveSession() {
        let active = dataVM.sessionsForDate(Date(), context: modelContext).first { $0.isActive }
        if let active {
            timerVM.resumeFromExisting(active)
        }
    }
}

struct DayCard: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let isToday: Bool
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        HStack(alignment: .center, spacing: 10 * s) {
            // Left: date info
            VStack(alignment: .leading, spacing: max(1, 1 * s)) {
                if isToday {
                    Text("今天")
                        .font(.system(size: 9 * s))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 4 * s)
                        .padding(.vertical, max(1, 1 * s))
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("今天")
                        .font(.system(size: 9 * s))
                        .foregroundStyle(.clear)
                        .padding(.horizontal, 4 * s)
                        .padding(.vertical, max(1, 1 * s))
                }
                HStack(spacing: 3 * s) {
                    Text(dayOfWeek)
                        .font(.system(size: 12 * s, weight: .medium))
                    Text("·")
                        .font(.system(size: 12 * s, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(monthDay)
                        .font(.system(size: 12 * s, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 78 * s)

            // Center: ring + right: bar + stats
            let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
                let d = dataVM.duration(for: cat.id, on: date)
                return d > 0 ? (Color(hex: cat.colorHex), d) : nil
            }

            HStack(spacing: 8 * s) {
                RingView(categoryDurations: durations, size: 34 * s, lineWidth: 4 * s)

                VStack(alignment: .leading, spacing: 3 * s) {
                    ForEach(categories) { cat in
                        let d = dataVM.duration(for: cat.id, on: date)
                        if d > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: max(CGFloat(d / (12 * 3600)) * 120 * s, 3 * s), height: 5 * s)
                        }
                    }
                }
                .padding(.leading, 15 * s)
            }
            .padding(.leading, 20 * s)

            Spacer()

            let total = dataVM.totalDuration(for: date)
            let count = categories.filter { dataVM.duration(for: $0.id, on: date) > 0 }.count
            if total > 0 {
                VStack(alignment: .leading, spacing: max(1, 1 * s)) {
                    Text(formatTotal(total))
                        .font(.system(size: 12 * s, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(count) 个类别")
                        .font(.system(size: 9 * s))
                        .foregroundStyle(.tertiary)
                }
                .offset(x: 15 * s)
            }

            Spacer().frame(width: 20 * s)

            Image(systemName: "chevron.right")
                .font(.system(size: 10 * s))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12 * s)
        .padding(.vertical, 8 * s)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "E"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }

    private var monthDay: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }

    private func formatTotal(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        return "\(h)h \(m)m"
    }
}

struct FutureDayCard: View {
    let date: Date
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        HStack(alignment: .center, spacing: 10 * s) {
            VStack(alignment: .leading, spacing: max(1, 1 * s)) {
                Text("今天")
                    .font(.system(size: 9 * s))
                    .foregroundStyle(.clear)
                    .padding(.horizontal, 4 * s)
                    .padding(.vertical, max(1, 1 * s))
                HStack(spacing: 3 * s) {
                    Text(dayOfWeek)
                        .font(.system(size: 12 * s, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.system(size: 12 * s, weight: .bold))
                        .foregroundStyle(.quaternary)
                    Text(monthDay)
                        .font(.system(size: 12 * s, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 78 * s)

            HStack(spacing: 8 * s) {
                Circle()
                    .stroke(Color.gray.opacity(0.08), lineWidth: 4 * s)
                    .frame(width: 34 * s, height: 34 * s)

                HStack(spacing: 6 * s) {
                    VStack(alignment: .leading, spacing: 3 * s) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clear)
                            .frame(width: 4 * s, height: 5 * s)
                    }
                    .padding(.leading, 15 * s)

                    VStack(alignment: .leading, spacing: max(1, 1 * s)) {
                        Text("--")
                            .font(.system(size: 12 * s))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 30 * s)
                }
            }
            .padding(.leading, 20 * s)

            Spacer(minLength: 2 * s)
        }
        .padding(.horizontal, 12 * s)
        .padding(.vertical, 8 * s)
        .background(Color.gray.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(0.4)
    }

    private var dayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "E"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }

    private var monthDay: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}

#Preview("iPhone 17") {
    ListView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environment(TimerViewModel())
}

#Preview("iPhone 17 Pro") {
    ListView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environment(TimerViewModel())
}
