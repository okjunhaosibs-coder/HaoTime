import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var selectedDate: Date = Date()
    @State private var weekStartDate: Date = WeekView.mondayOfWeek(containing: Date())
    @State private var tappedCategory: Category?
    @State private var showCategorySessions = false

    var body: some View {
        VStack(spacing: 0) {
            TimerBar(
                categories: dataVM.activeCategories,
                timerVM: timerVM,
                modelContext: modelContext,
                onDataDidChange: { refreshData() }
            )

            Divider()

            DayDetailView(
                date: selectedDate,
                categories: dataVM.activeCategories,
                dataVM: dataVM,
                ringSize: 150,
                context: modelContext,
                onCategoryTap: { cat in
                    tappedCategory = cat
                    showCategorySessions = true
                }
            )

            Divider()

            weekStrip
        }
        .frame(minWidth: 700, minHeight: 500)
        .popover(isPresented: $showCategorySessions) {
            if let cat = tappedCategory {
                CategorySessionsView(
                    date: selectedDate,
                    category: cat,
                    context: modelContext
                )
            }
        }
        .onAppear {
            dataVM.fetchCategories(context: modelContext)
            refreshData()
            resumeActiveSession()
        }
        .onChange(of: weekStartDate) { _, _ in refreshData() }
        .onChange(of: showCategorySessions) { _, newValue in
            if !newValue { refreshData() }
        }
        .onChange(of: timerVM.isRunning) { _, running in
            if !running { refreshData() }
        }
    }

    private let visibleWeekCount = 12

    private var weekStrip: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                ForEach(0..<visibleWeekCount, id: \.self) { weekOffset in
                    let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -weekOffset, to: weekStartDate)!
                    weekRow(starting: weekStart)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func weekRow(starting monday: Date) -> some View {
        let days = (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: monday)
        }
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: monday)!
        let isCurrentWeek = Calendar.current.isDate(monday, equalTo: weekStartDate, toGranularity: .weekOfYear)

        return VStack(spacing: 10) {
            HStack {
                if isCurrentWeek {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
                Text(weekRange(for: monday, ending: endDate))
                    .font(.caption)
                    .foregroundStyle(isCurrentWeek ? Color.accentColor : .secondary)
            }

            HStack(spacing: 16) {
                ForEach(days, id: \.self) { date in
                    DayColumn(
                        date: date,
                        categories: dataVM.activeCategories,
                        dataVM: dataVM,
                        isToday: Calendar.current.isDateInToday(date),
                        isFuture: date > Date(),
                        action: { selectedDate = date }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func weekRange(for start: Date, ending end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return "\(f.string(from: start)) — \(f.string(from: end))"
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

    static func mondayOfWeek(containing date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offset = weekday == 1 ? -6 : 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: offset, to: date) else { return date }
        return calendar.startOfDay(for: monday)
    }
}

#Preview("Week View - Mac Layout") {
    WeekView()
        .modelContainer(PreviewHelpers.previewContainer)
        .frame(width: 900, height: 600)
}
