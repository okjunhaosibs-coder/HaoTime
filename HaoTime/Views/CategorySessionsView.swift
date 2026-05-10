import SwiftUI
import SwiftData

struct CategorySessionsView: View {
    let date: Date
    let category: Category
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [Session] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(timeRange(session))
                                .font(.subheadline)
                            Text(formatDuration(session.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Circle()
                            .fill(Color(hex: category.colorHex))
                            .frame(width: 10, height: 10)
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
            .navigationTitle("\(category.name) · \(formattedDate)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                loadSessions()
            }
        }
        .frame(minWidth: 360, minHeight: 300)
    }

    private func loadSessions() {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate {
                $0.startTime >= startOfDay &&
                $0.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let allSessions = (try? context.fetch(descriptor)) ?? []
        sessions = allSessions.filter { $0.category?.id == category.id }
        print("[DIAG] CategorySessionsView '\(category.name)' loaded \(sessions.count) sessions")
        for s in sessions {
            print("[DIAG]   id=\(s.id.uuidString) cat=\(s.category?.name ?? "nil") start=\(s.startTime.formatted(.iso8601)) end=\(s.endTime?.formatted(.iso8601) ?? "nil") dur=\(s.duration)")
        }
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
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}
