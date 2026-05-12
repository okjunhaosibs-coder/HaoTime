import Foundation
import SwiftData
import SwiftUI
import Observation
#if os(iOS)
import HealthKit
#endif

@Observable
final class DataViewModel {
    var categories: [Category] = []
    var activeCategories: [Category] {
        categories.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var dailyAggregates: [String: [UUID: TimeInterval]] = [:]

    func fetchCategories(context: ModelContext) {
        // Clean up orphaned nil-category sessions
        let allSessions = (try? context.fetch(FetchDescriptor<Session>())) ?? []
        for s in allSessions where s.category == nil { context.delete(s) }
        if allSessions.contains(where: { $0.category == nil }) { try? context.save() }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        var list = (try? context.fetch(descriptor)) ?? []
        var didChange = false
        // dedup: keep first per UUID+name, migrate sessions before deleting duplicates
        var keptForName: [String: Category] = [:]
        var toDelete: [Category] = []
        for cat in list {
            if let keeper = keptForName[cat.name] {
                // migrate sessions from DB before deleting duplicate category
                let allSessions = (try? context.fetch(FetchDescriptor<Session>())) ?? []
                for s in allSessions where s.category?.id == cat.id { s.category = keeper }
                toDelete.append(cat)
            } else {
                keptForName[cat.name] = cat
            }
        }
        for dup in toDelete {
            context.delete(dup)
            if let idx = list.firstIndex(where: { $0 === dup }) { list.remove(at: idx) }
            didChange = true
        }
        // ensure presets
        let existingIDs = Set(list.map { $0.id })
        for (index, preset) in Category.presets.enumerated() {
            let pid = UUID(uuidString: Category.presetIDs[index]) ?? UUID()
            guard !existingIDs.contains(pid) else { continue }
            let cat = Category(
                id: pid, name: preset.name, colorHex: preset.colorHex,
                iconName: preset.iconName, sortOrder: index, builtInName: preset.builtInName
            )
            context.insert(cat)
            didChange = true
        }
        categories = (try? context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
    }

    func sessionsForDate(_ date: Date, context: ModelContext) -> [Session] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= startOfDay && $0.startTime < endOfDay },
            sortBy: [SortDescriptor(\.startTime)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func aggregateForWeek(containing date: Date, context: ModelContext) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let mondayOffset = weekday == 1 ? -6 : 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: date) else { return }
        let startOfMonday = calendar.startOfDay(for: monday)

        dailyAggregates = [:]

        for dayOffset in 0..<7 {
            guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonday) else { continue }
            aggregateDay(dayStart, context: context)
        }
    }

    func aggregateForWeeks(weekCount: Int, endingOn date: Date, context: ModelContext) {
        dailyAggregates = [:]
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        let totalDays = weekCount * 7

        for dayOffset in 0..<totalDays {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            aggregateDay(dayStart, context: context)
        }

        #if os(iOS)
        let todayKey = Self.dateFormatter.string(from: startOfToday)
        let todayData = dailyAggregates[todayKey] ?? [:]
        var payload: [String: TimeInterval] = [:]
        for (uuid, dur) in todayData {
            payload[uuid.uuidString] = dur
        }
        var names: [String: String] = [:]
        var icons: [String: String] = [:]
        var colors: [String: String] = [:]
        for cat in activeCategories {
            names[cat.id.uuidString] = cat.name
            icons[cat.id.uuidString] = cat.iconName
            colors[cat.id.uuidString] = cat.colorHex
        }
        let total = totalDuration(for: Date())
        WatchConnectivityManager.shared.sendRingData(durations: payload, total: total, names: names, icons: icons, colors: colors)
        #endif
    }

    private func aggregateDay(_ dayStart: Date, context: ModelContext) {
        let calendar = Calendar.current
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let dateKey = Self.dateFormatter.string(from: dayStart)

        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= dayStart && $0.startTime < dayEnd && $0.endTime != nil }
        )
        let sessions = (try? context.fetch(descriptor)) ?? []

        var categoryDurations: [UUID: TimeInterval] = [:]
        for session in sessions {
            guard let catID = session.category?.id else { continue }
            categoryDurations[catID, default: 0] += session.duration
        }
        dailyAggregates[dateKey] = categoryDurations
    }

    func totalDuration(for date: Date) -> TimeInterval {
        let key = Self.dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        let activeIDs = Set(activeCategories.map { $0.id })
        return dailyAggregates[key]?.filter { activeIDs.contains($0.key) }.values.reduce(0, +) ?? 0
    }

    func duration(for categoryID: UUID, on date: Date) -> TimeInterval {
        let key = Self.dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        return dailyAggregates[key]?[categoryID] ?? 0
    }

    func addCategory(name: String, colorHex: String, iconName: String, context: ModelContext) {
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let cat = Category(name: name, colorHex: colorHex, iconName: iconName, sortOrder: maxOrder + 1)
        context.insert(cat)
        try? context.save()
        fetchCategories(context: context)
    }

    func updateCategory(_ category: Category, context: ModelContext) {
        try? context.save()
        fetchCategories(context: context)
        #if os(iOS)
        aggregateForWeeks(weekCount: 4, endingOn: Date(), context: context)
        #endif
    }

    func archiveCategory(_ category: Category, context: ModelContext) {
        guard category.builtInName == nil, activeCategories.count > 1 else { return }
        category.isArchived = true
        try? context.save()
        fetchCategories(context: context)
    }

    func moveCategory(from source: IndexSet, to destination: Int, context: ModelContext) {
        var active = activeCategories
        active.move(fromOffsets: source, toOffset: destination)
        for (index, cat) in active.enumerated() {
            cat.sortOrder = index
        }
        try? context.save()
        fetchCategories(context: context)
    }

    func deleteSession(_ session: Session, context: ModelContext) {
        context.delete(session)
        try? context.save()
    }

    func deduplicateSessions(context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<Session> { $0.startTime >= startOfDay && $0.startTime < dayEnd }
        let all = (try? context.fetch(FetchDescriptor<Session>(predicate: predicate))) ?? []
        var keptForTime: [String: Session] = [:]
        var toDelete: [Session] = []
        for s in all {
            let key = "\(Int(s.startTime.timeIntervalSince1970 / 2))|\(Int((s.endTime?.timeIntervalSince1970 ?? 0) / 2))"
            if let existing = keptForTime[key] {
                // keep the one with a category, delete the nil-category one
                if s.category == nil { toDelete.append(s) }
                else if existing.category == nil { toDelete.append(existing); keptForTime[key] = s }
                else { toDelete.append(s) }
            } else {
                keptForTime[key] = s
            }
        }
        guard !toDelete.isEmpty else { return }
        for dup in toDelete { context.delete(dup) }
        try? context.save()
    }

    #if os(iOS)
    func importTodayWorkouts(context: ModelContext) async {
        let workouts = await HealthKitManager.shared.fetchTodayWorkouts()
                guard !workouts.isEmpty else { return }

        let allCats = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let sportCategory = allCats.first(where: { $0.builtInName == Category.sportCategoryName })
            ?? createSportCategory(context: context)

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let existingSessions = sessionsForDate(Date(), context: context)
            .filter { $0.category?.id == sportCategory.id }

        for workout in workouts {
            let duration = workout.duration
            guard duration >= 5 else { continue }

            let sessionStart = workout.startDate
            let sessionEnd = workout.endDate
            let alreadyExists = existingSessions.contains { existing in
                abs(existing.startTime.timeIntervalSince(sessionStart)) < 60
            }
            guard !alreadyExists else { continue }

            let session = Session(
                category: sportCategory,
                startTime: sessionStart,
                endTime: sessionEnd
            )
            context.insert(session)
        }
    }

    private func createSportCategory(context: ModelContext) -> Category {
        let pid = UUID(uuidString: Category.presetIDs[0]) ?? UUID()
        let cat = Category(
            id: pid,
            name: "运动",
            colorHex: "#FF6B6B",
            iconName: "figure.run",
            sortOrder: 0,
            builtInName: Category.sportCategoryName
        )
        context.insert(cat)
        try? context.save()
        categories.append(cat)
        return cat
    }
    #endif

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
