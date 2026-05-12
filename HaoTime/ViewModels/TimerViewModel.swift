import Foundation
import SwiftData
import Observation

@Observable
final class TimerViewModel {
    var activeSession: Session?
    var elapsedString: String = "00:00:00"
    var isShowingSwitchAlert = false
    var pendingCategory: Category?

    private var timer: Timer?
    private var remoteStartTime: Date?
    private var remoteCategoryID: String?
    var remoteCategoryName: String? = nil
    var remoteCategoryColor: String? = nil
    var remoteCategoryIcon: String? = nil
    #if os(macOS)
    private var suspendedCategory: Category?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    #endif

    var isRunning: Bool { activeSession != nil || remoteStartTime != nil }

    #if os(macOS)
    func setupSleepWakeHandlers(context: ModelContext) {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.isRunning else { return }
            self.suspendedCategory = self.activeSession?.category
            self.stop(context: context)
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, let cat = self.suspendedCategory else { return }
            self.suspendedCategory = nil
            self.start(category: cat, context: context)
        }
    }
    #endif

    func start(category: Category, context: ModelContext) {
        if activeSession != nil {
            pendingCategory = category
            isShowingSwitchAlert = true
            return
        }
        beginSession(category: category, context: context)
    }

    func confirmSwitch(context: ModelContext) {
        guard let pending = pendingCategory else { return }
        stop(context: context)
        beginSession(category: pending, context: context)
        isShowingSwitchAlert = false
        pendingCategory = nil
    }

    func cancelSwitch() {
        isShowingSwitchAlert = false
        pendingCategory = nil
    }

    func stop(context: ModelContext) {
        guard isRunning else { return }
        if remoteStartTime != nil {
            let start = remoteStartTime!
            let cid = remoteCategoryID ?? ""
            let end = Date()
            remoteStartTime = nil
            remoteCategoryName = nil; remoteCategoryColor = nil; remoteCategoryIcon = nil; remoteCategoryID = nil
            timer?.invalidate()
            timer = nil
            elapsedString = "00:00:00"
            #if os(iOS) || os(watchOS)
            WatchConnectivityManager.shared.sendStop(categoryID: cid, startTime: start, endTime: end)
            #endif
            return
        }
        guard let active = activeSession else { return }
        active.endTime = Date()
        if active.duration < 5 {
            context.delete(active)
            try? context.save()
        } else {
            try? context.save()
        }
        activeSession = nil
        timer?.invalidate()
        timer = nil
        elapsedString = "00:00:00"
        #if os(iOS) || os(watchOS)
        let cid = active.category?.id.uuidString ?? ""
        let st = active.startTime
        let et = active.endTime ?? Date()
        WatchConnectivityManager.shared.sendStop(categoryID: cid, startTime: st, endTime: et)
        #endif
    }

    func toggle(category: Category, context: ModelContext) {
        if let active = activeSession, active.category?.id == category.id {
            stop(context: context)
        } else {
            start(category: category, context: context)
        }
    }

    private func beginSession(category: Category, context: ModelContext) {
        let session = Session(category: category, startTime: Date())
                context.insert(session)
        try? context.save()
        activeSession = session
        startTimer()
        #if os(iOS) || os(watchOS)
        WatchConnectivityManager.shared.sendStart(
            categoryID: category.id.uuidString,
            startTime: session.startTime
        )
        #endif
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed: TimeInterval
            if let session = self.activeSession {
                elapsed = session.duration
            } else if let remoteStart = self.remoteStartTime {
                elapsed = Date().timeIntervalSince(remoteStart)
            } else {
                return
            }
            let h = Int(elapsed) / 3600
            let m = (Int(elapsed) % 3600) / 60
            let s = Int(elapsed) % 60
            self.elapsedString = String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    func resumeFromExisting(_ session: Session) {
        activeSession = session
        startTimer()
    }

    #if os(iOS) || os(watchOS)
    func handleRemoteStart(categoryID: String, startTime: Date, context: ModelContext) {
        if isRunning { handleRemoteStop(categoryID: "", startTime: Date(), endTime: Date(), context: context) }
        remoteStartTime = startTime
        remoteCategoryID = categoryID
        if let uuid = UUID(uuidString: categoryID) {
            let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == uuid })
            if let cat = (try? context.fetch(descriptor))?.first {
                remoteCategoryName = cat.name
                remoteCategoryColor = cat.colorHex
                remoteCategoryIcon = cat.iconName
            }
        }
        startTimer()
    }

    func handleRemoteStop(categoryID: String, startTime: Date, endTime: Date, context: ModelContext) {
        remoteStartTime = nil
        remoteCategoryName = nil; remoteCategoryColor = nil; remoteCategoryIcon = nil; remoteCategoryID = nil
        // Originator: close own session and send real data back
        if activeSession != nil {
            stop(context: context)
            return
        }
        // Receiver: persist the remote session data (dedup by startTime)
        if !categoryID.isEmpty, endTime.timeIntervalSince(startTime) >= 5,
           let uuid = UUID(uuidString: categoryID) {
            let catDescriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == uuid })
            if let cat = (try? context.fetch(catDescriptor))?.first {
                let existingPred = #Predicate<Session> { $0.category?.id == uuid && $0.startTime == startTime }
                let existing = try? context.fetch(FetchDescriptor<Session>(predicate: existingPred))
                if existing?.isEmpty != false {
                    let session = Session(category: cat, startTime: startTime, endTime: endTime)
                    context.insert(session)
                    try? context.save()
                }
            }
        }
        activeSession = nil
        timer?.invalidate()
        timer = nil
        elapsedString = "00:00:00"
    }
    #endif
}
