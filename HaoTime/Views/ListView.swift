import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var selectedDate: Date?
    @State private var showDayDetail = false
    @State private var tappedCategory: Category?
    @State private var showCategorySessions = false
    @State private var weekStartDate: Date = WeekView.mondayOfWeek(containing: Date())

    var body: some View {
        VStack(spacing: 0) {
            TimerBar(
                categories: dataVM.activeCategories,
                timerVM: timerVM,
                modelContext: modelContext,
                onDataDidChange: { refreshData() }
            )

            ScrollView {
                todayDetail
            }

            Divider()
                .padding(.horizontal)

            weekCards

            Text("左右滑动查看更多历史记录")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 15)
                .padding(.bottom, 8)
        }
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
                ringSize: 80,
                context: modelContext,
                onCategoryTap: { cat in
                    tappedCategory = cat
                    selectedDate = Date()
                    showCategorySessions = true
                }
            )
        }
    }

    private let visibleWeekCount = 12
    @State private var currentWeekIndex = 11

    private var weekCards: some View {
        TabView(selection: $currentWeekIndex) {
            ForEach((0..<visibleWeekCount).reversed(), id: \.self) { displayIndex in
                let weekOffset = visibleWeekCount - 1 - displayIndex
                let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weekOffset, to: weekStartDate)!
                weekSection(starting: weekStart)
                    .tag(displayIndex)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .frame(height: 420)
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
        dataVM.aggregateForWeeks(weekCount: visibleWeekCount, endingOn: weekStartDate, context: modelContext)
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

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left: date info
            VStack(alignment: .leading, spacing: 1) {
                if isToday {
                    Text("今天")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("今天")
                        .font(.system(size: 9))
                        .foregroundStyle(.clear)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                }
                HStack(spacing: 3) {
                    Text(dayOfWeek)
                        .font(.system(size: 12, weight: .medium))
                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(monthDay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 78)

            // Center: ring + right: bar + stats
            let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
                let d = dataVM.duration(for: cat.id, on: date)
                return d > 0 ? (Color(hex: cat.colorHex), d) : nil
            }

            HStack(spacing: 8) {
                RingView(categoryDurations: durations, size: 34, lineWidth: 4)

                HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(categories) { cat in
                        let d = dataVM.duration(for: cat.id, on: date)
                        if d > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: max(CGFloat(d / (12 * 3600)) * 120, 3), height: 5)
                        }
                    }
                }
                .padding(.leading, 15)

                let total = dataVM.totalDuration(for: date)
                let count = categories.filter { dataVM.duration(for: $0.id, on: date) > 0 }.count
                if total > 0 {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(formatTotal(total))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(count) 个类别")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 30)
                }
            }

            }
            .padding(.leading, 20)

            Spacer(minLength: 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("今天")
                    .font(.system(size: 9))
                    .foregroundStyle(.clear)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                HStack(spacing: 3) {
                    Text(dayOfWeek)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.quaternary)
                    Text(monthDay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 78)

            HStack(spacing: 8) {
                Circle()
                    .stroke(Color.gray.opacity(0.08), lineWidth: 4)
                    .frame(width: 34, height: 34)

                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clear)
                            .frame(width: 4, height: 5)
                    }
                    .padding(.leading, 15)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("--")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 30)
                }
            }
            .padding(.leading, 20)

            Spacer(minLength: 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
        .previewDevice("iPhone 17")
}

#Preview("iPhone 17 Pro") {
    ListView()
        .modelContainer(PreviewHelpers.previewContainer)
        .previewDevice("iPhone 17 Pro")
}
