import SwiftUI
import SwiftData

struct DaySessionsView: View {
    let date: Date
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [Session] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    HStack {
                        Circle()
                            .fill(Color(hex: session.category?.colorHex ?? "#888888"))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading) {
                            Text(session.category?.name ?? "未分类")
                                .font(.subheadline)
                            Text(timeRange(session))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatDuration(session.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteSession(session)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(formattedDate)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                loadSessions()
            }
        }
    }

    private func loadSessions() {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= startOfDay && $0.startTime < endOfDay },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        sessions = (try? context.fetch(descriptor)) ?? []
    }

    private func deleteSession(_ session: Session) {
        context.delete(session)
        try? context.save()
        loadSessions()
    }

    private func timeRange(_ session: Session) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let start = f.string(from: session.startTime)
        if let end = session.endTime {
            return "\(start) - \(f.string(from: end))"
        }
        return "\(start) - 计时中"
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        return "\(h)h \(m)m"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}
