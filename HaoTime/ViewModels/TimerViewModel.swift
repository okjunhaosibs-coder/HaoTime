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

    var isRunning: Bool { activeSession != nil }

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
        guard let active = activeSession else { return }
        active.endTime = Date()
        try? context.save()
        activeSession = nil
        timer?.invalidate()
        timer = nil
        elapsedString = "00:00:00"
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
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let session = self.activeSession else { return }
            let elapsed = session.duration
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
}
