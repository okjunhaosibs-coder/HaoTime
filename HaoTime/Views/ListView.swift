import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var selectedDate: Date?
    @State private var showDayDetail = false
    @State private var weekStartDate: Date = WeekView.mondayOfWeek(containing: Date())

    var body: some View {
        VStack(spacing: 0) {
            TimerBar(
                categories: dataVM.activeCategories,
                timerVM: timerVM,
                modelContext: modelContext
            )

            ScrollView {
                VStack(spacing: 0) {
                    todayDetail

                    Divider()
                        .padding(.horizontal)

                    weekCards
                }
            }
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
                context: modelContext
            )
        }
    }

    private var weekCards: some View {
        VStack(spacing: 8) {
            Text("本周")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(daysInWeek, id: \.self) { date in
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

            Text("上拉查看更多")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 12)
        }
    }

    private var daysInWeek: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: weekStartDate)
        }
    }

    private var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: Date())
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
}

struct DayCard: View {
    let date: Date
    let categories: [Category]
    let dataVM: DataViewModel
    let isToday: Bool

    var body: some View {
        HStack(spacing: 12) {
            let durations = categories.compactMap { cat -> (color: Color, duration: TimeInterval)? in
                let d = dataVM.duration(for: cat.id, on: date)
                return d > 0 ? (Color(hex: cat.colorHex), d) : nil
            }
            RingView(categoryDurations: durations, size: 44, lineWidth: 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if isToday {
                        Text("今天")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                ForEach(categories) { cat in
                    let d = dataVM.duration(for: cat.id, on: date)
                    if d > 0 {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: max(CGFloat(d / (12 * 3600)) * 120, 4), height: 6)
                        }
                    }
                }
                HStack(spacing: 4) {
                    let total = dataVM.totalDuration(for: date)
                    if total > 0 {
                        Text(formatTotal(total))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    let count = categories.filter { dataVM.duration(for: $0.id, on: date) > 0 }.count
                    if count > 0 {
                        Text("· \(count) 个类别")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "E · M月d日"
        f.locale = Locale(identifier: "zh_CN")
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
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.gray.opacity(0.08), lineWidth: 5)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading) {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Text("--")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(0.4)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "E · M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}
