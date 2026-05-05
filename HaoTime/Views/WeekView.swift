import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var selectedDate: Date = Date()
    @State private var weekStartDate: Date = WeekView.mondayOfWeek(containing: Date())

    var body: some View {
        VStack(spacing: 0) {
            TimerBar(
                categories: dataVM.activeCategories,
                timerVM: timerVM,
                modelContext: modelContext
            )

            Divider()

            DayDetailView(
                date: selectedDate,
                categories: dataVM.activeCategories,
                dataVM: dataVM,
                ringSize: 160
            )

            Divider()

            weekStrip
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            dataVM.fetchCategories(context: modelContext)
            refreshData()
            resumeActiveSession()
        }
        .onChange(of: weekStartDate) { _, _ in refreshData() }
    }

    private var weekStrip: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { shiftWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 160)

                Button(action: { shiftWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                ForEach(daysInWeek, id: \.self) { date in
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
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private var daysInWeek: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: weekStartDate)
        }
    }

    private var weekRangeText: String {
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return "\(f.string(from: weekStartDate)) — \(f.string(from: endDate))"
    }

    private func shiftWeek(by weeks: Int) {
        guard let newStart = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: weekStartDate) else { return }
        weekStartDate = newStart
    }

    private func refreshData() {
        dataVM.aggregateForWeek(containing: weekStartDate, context: modelContext)
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
