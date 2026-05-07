import WatchConnectivity
import Foundation

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    var isReachable = false
    var onRemoteStart: ((String, Date) -> Void)?
    var onRemoteStop: (() -> Void)?

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

    private func send(message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("[WCS] Not reachable")
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("[WCS] Send error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        DispatchQueue.main.async {
            switch action {
            case "start":
                guard let id = message["categoryID"] as? String,
                      let startTime = message["startTime"] as? Date else { return }
                self.onRemoteStart?(id, startTime)
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
        isReachable = session.isReachable
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        isReachable = session.isReachable
    }
}
