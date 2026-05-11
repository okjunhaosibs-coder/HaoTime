#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif
import Foundation

#if os(iOS) || os(watchOS)
@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    var isReachable = false
    var onRemoteStart: ((String, Date) -> Void)?
    var onRemoteStop: (() -> Void)?
    var onRingData: (([String: TimeInterval], TimeInterval, [String: String], [String: String], [String: String]) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendStart(categoryID: String, startTime: Date) {
        send(message: [
            "action": "start",
            "categoryID": categoryID,
            "startTime": startTime
        ])
    }

    func sendStop() {
        send(message: ["action": "stop"])
    }

    func sendRingData(durations: [String: TimeInterval], total: TimeInterval, names: [String: String], icons: [String: String], colors: [String: String]) {
        send(message: [
            "action": "ringData",
            "durations": durations,
            "total": total,
            "names": names,
            "icons": icons,
            "colors": colors
        ])
    }

    private func send(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("[WCS] Send error: \(error.localizedDescription)")
            }
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handle(message: message)
    }

    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(message: userInfo)
    }

    private func handle(message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        DispatchQueue.main.async {
            switch action {
            case "start":
                guard let id = message["categoryID"] as? String,
                      let startTime = message["startTime"] as? Date else { return }
                self.onRemoteStart?(id, startTime)
            case "ringData":
                guard let durations = message["durations"] as? [String: TimeInterval],
                      let total = message["total"] as? TimeInterval,
                      let names = message["names"] as? [String: String],
                      let icons = message["icons"] as? [String: String],
                      let colors = message["colors"] as? [String: String] else { return }
                self.onRingData?(durations, total, names, icons, colors)
            case "stop":
                self.onRemoteStop?()
            default:
                break
            }
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error {
            print("[WCS] Activation error: \(error.localizedDescription)")
        }
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }
}
#endif
