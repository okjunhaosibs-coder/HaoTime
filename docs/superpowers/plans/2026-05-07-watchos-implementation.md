# watchOS HaoTime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add watchOS target with today glance (ring + category list) and quick timer with real-time start/stop sync via WatchConnectivity.

**Architecture:** CloudKit (SwiftData) for persistent storage. WatchConnectivity for real-time start/stop messages. Shared models and view models added to both targets. New watch-specific views in `HaoTimeWatch/`.

**Tech Stack:** SwiftUI, SwiftData (CloudKit), WatchConnectivity, watchOS 10+

---

## File Map

| File | Target(s) | Action |
|------|-----------|--------|
| `HaoTime/Helpers/WatchConnectivityManager.swift` | iOS + watchOS | CREATE |
| `HaoTime/Models/Category.swift` | +watchOS | Target membership |
| `HaoTime/Models/Session.swift` | +watchOS | Target membership |
| `HaoTime/ViewModels/DataViewModel.swift` | +watchOS | Target membership |
| `HaoTime/ViewModels/TimerViewModel.swift` | iOS + watchOS | MODIFY |
| `HaoTime/Helpers/LayoutScale.swift` | +watchOS | Target membership |
| `HaoTime/Views/RingView.swift` | +watchOS | Target membership |
| `HaoTime/HaoTimeApp.swift` | iOS | MODIFY (shared VM + WCS handlers) |
| `HaoTime/Views/ListView.swift` | iOS | MODIFY (1 line: @State → @Environment) |
| `HaoTime/Views/WeekView.swift` | macOS | MODIFY (1 line: @State → @Environment) |
| `HaoTimeWatch/HaoTimeWatchApp.swift` | watchOS | CREATE |
| `HaoTimeWatch/WatchMainView.swift` | watchOS | CREATE |
| `HaoTimeWatch/WatchTimerView.swift` | watchOS | CREATE |

---

### Task 0: Add watchOS Target in Xcode

**Files:** None (Xcode UI operation)

- [ ] **Step 1: Add Watch App target**

In Xcode, open `/Users/junhao/agent/Claude/Time/HaoTime/HaoTime.xcodeproj`.
File → New → Target → watchOS → Watch App.
- Product Name: `HaoTimeWatch`
- Uncheck "Include Notification Scene"
- Uncheck "Include Companion App"
- Bundle Identifier: use the iOS bundle ID + `.watchkitapp`

- [ ] **Step 2: Create physical folder**

```bash
mkdir -p /Users/junhao/agent/Claude/Time/HaoTime/HaoTimeWatch
```

- [ ] **Step 3: Delete Xcode-generated template files in HaoTimeWatch group**

Remove: `ContentView.swift`, `Assets.xcassets` (the template ones in the HaoTimeWatch group, NOT in HaoTime).

- [ ] **Step 4: Set shared file target memberships**

In Xcode Project Navigator, select each file. In File Inspector → Target Membership, check `HaoTimeWatch`:

- `HaoTime/Models/Category.swift`
- `HaoTime/Models/Session.swift`
- `HaoTime/ViewModels/DataViewModel.swift`
- `HaoTime/Helpers/LayoutScale.swift`
- `HaoTime/Views/RingView.swift`

The `TimerViewModel.swift` will be handled when we modify it (already in both targets).

- [ ] **Step 5: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add -A
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "chore: add watchOS target"
```

---

### Task 1: WatchConnectivityManager (Shared)

**Files:**
- Create: `HaoTime/Helpers/WatchConnectivityManager.swift`

- [ ] **Step 1: Create the file**

```swift
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
```

- [ ] **Step 2: Set target membership for both targets**

In Xcode: select file → Target Membership → check BOTH `HaoTime` and `HaoTimeWatch`.

- [ ] **Step 3: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTime/Helpers/WatchConnectivityManager.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: add WatchConnectivityManager for start/stop sync"
```

---

### Task 2: Update TimerViewModel

**Files:**
- Modify: `HaoTime/ViewModels/TimerViewModel.swift`

- [ ] **Step 1: Add WCS send after local start**

In `beginSession(category:context:)`, find:

```swift
activeSession = session
startTimer()
```

Replace with:

```swift
activeSession = session
startTimer()
if let cat = activeSession?.category {
    WatchConnectivityManager.shared.sendStart(
        categoryID: cat.id.uuidString,
        startTime: activeSession?.startTime ?? Date()
    )
}
```

- [ ] **Step 2: Add WCS send after local stop**

In `stop(context:)`, find:

```swift
active.endTime = Date()
try? context.save()
activeSession = nil
timer?.invalidate()
timer = nil
elapsedString = "00:00:00"
```

After `elapsedString = "00:00:00"`, add:

```swift
WatchConnectivityManager.shared.sendStop()
```

- [ ] **Step 3: Add remote handler methods**

Add these two methods to `TimerViewModel`, below the `resumeFromExisting` method:

```swift
func handleRemoteStart(categoryID: String, startTime: Date, context: ModelContext) {
    guard activeSession == nil else { return }
    guard let uuid = UUID(uuidString: categoryID) else { return }
    let descriptor = FetchDescriptor<Category>(
        predicate: #Predicate { $0.id == uuid }
    )
    guard let category = (try? context.fetch(descriptor))?.first else { return }
    let session = Session(category: category, startTime: startTime)
    activeSession = session
    startTimer()
}

func handleRemoteStop(context: ModelContext) {
    guard let active = activeSession else { return }
    active.endTime = Date()
    try? context.save()
    activeSession = nil
    timer?.invalidate()
    timer = nil
    elapsedString = "00:00:00"
}
```

- [ ] **Step 4: Add SwiftData import**

Ensure `import SwiftData` is at the top of the file (needed for `FetchDescriptor`).

- [ ] **Step 5: Set target membership**

In Xcode: select TimerViewModel.swift → Target Membership → ensure BOTH `HaoTime` and `HaoTimeWatch` are checked.

- [ ] **Step 6: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTime/ViewModels/TimerViewModel.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: add WCS send + remote start/stop to TimerViewModel"
```

---

### Task 3: Activate WCS + Shared TimerViewModel on iOS

**Files:**
- Modify: `HaoTime/HaoTimeApp.swift`
- Modify: `HaoTime/Views/ListView.swift` (1 line: `@State` → `@Environment`)
- Modify: `HaoTime/Views/WeekView.swift` (1 line: `@State` → `@Environment`)

- [ ] **Step 1: Create shared TimerViewModel and inject via environment**

In `HaoTimeApp.swift`, add `@State private var timerVM`:

```swift
@main
struct HaoTimeApp: App {
    var sharedModelContainer: ModelContainer = {
        ...
    }()

    @State private var timerVM = TimerViewModel()
```

Replace the `WindowGroup` body:

```swift
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerVM)
                .onAppear {
                    WatchConnectivityManager.shared.activate()
                    setupWCSHandlers()
                }
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .windowResizability(.contentMinSize)
        #endif
    }

    @MainActor
    private func setupWCSHandlers() {
        let context = sharedModelContainer.mainContext
        WatchConnectivityManager.shared.onRemoteStart = { [weak timerVM] categoryID, startTime in
            timerVM?.handleRemoteStart(
                categoryID: categoryID,
                startTime: startTime,
                context: context
            )
        }
        WatchConnectivityManager.shared.onRemoteStop = { [weak timerVM] in
            timerVM?.handleRemoteStop(context: context)
        }
    }
```

- [ ] **Step 2: Change ListView and WeekView to use Environment instead of @State**

In `ListView.swift`, find:

```swift
@State private var timerVM = TimerViewModel()
```

Replace with:

```swift
@Environment(TimerViewModel.self) private var timerVM
```

In `WeekView.swift`, find:

```swift
@State private var timerVM = TimerViewModel()
```

Replace with:

```swift
@Environment(TimerViewModel.self) private var timerVM
```

Both files already import `Observation` (via `TimerViewModel`). This is a 1-line wiring change — same name, same type, same usage, just sourced from the shared environment.

- [ ] **Step 3: Verify target membership for TimerViewModel**

In Xcode: select `TimerViewModel.swift` → Target Membership → check BOTH `HaoTime` and `HaoTimeWatch`.

- [ ] **Step 4: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTime/HaoTimeApp.swift HaoTime/Views/ListView.swift HaoTime/Views/WeekView.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: share TimerViewModel via environment for WCS live sync"
```

---

### Task 4: watchOS App Entry

**Files:**
- Create: `HaoTimeWatch/HaoTimeWatchApp.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI
import SwiftData

@main
struct HaoTimeWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Category.self, Session.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var dataVM = DataViewModel()
    @State private var timerVM = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            WatchMainView(dataVM: dataVM, timerVM: timerVM)
                .onAppear {
                    dataVM.fetchCategories(context: sharedModelContainer.mainContext)
                    dataVM.aggregateForWeek(containing: Date(),
                        context: sharedModelContainer.mainContext)
                    WatchConnectivityManager.shared.activate()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Note:** CloudKit configuration will be added when the provisioning profile is set up. For now, local SwiftData works on watch and syncs when both devices share the same iCloud container ID.

- [ ] **Step 2: Verify target membership**

Ensure only `HaoTimeWatch` target is checked.

- [ ] **Step 3: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTimeWatch/HaoTimeWatchApp.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: add watchOS app entry"
```

---

### Task 5: WatchMainView — Ring + Category List

**Files:**
- Create: `HaoTimeWatch/WatchMainView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI
import SwiftData

struct WatchMainView: View {
    let dataVM: DataViewModel
    let timerVM: TimerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutScale) private var layoutScale
    @State private var selectedCategory: Category?

    var body: some View {
        let s = layoutScale
        GeometryReader { geo in
            let ringSize = min(geo.size.height * 0.5, 58)
            HStack(spacing: 8 * s) {
                ringSection(size: ringSize)

                VStack(alignment: .leading, spacing: max(4, 4 * s)) {
                    ForEach(dataVM.activeCategories) { cat in
                        categoryRow(cat)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(item: $selectedCategory) { category in
            WatchTimerView(
                category: category,
                timerVM: timerVM,
                onDismiss: {
                    selectedCategory = nil
                }
            )
        }
        .onAppear {
            WatchConnectivityManager.shared.onRemoteStop = { [timerVM] in
                timerVM.handleRemoteStop(context: modelContext)
                selectedCategory = nil
            }
        }
    }

    private func ringSection(size: CGFloat) -> some View {
        let s = layoutScale
        let durations = dataVM.activeCategories.compactMap { cat -> (Color, TimeInterval)? in
            let d = dataVM.duration(for: cat.id, on: Date())
            return d > 0 ? (Color(hex: cat.colorHex), d) : nil
        }
        let total = dataVM.totalDuration(for: Date())

        return RingView(categoryDurations: durations, size: size)
            .overlay {
                Text(formatTotal(total))
                    .font(.system(size: 8 * s, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
    }

    private func categoryRow(_ cat: Category) -> some View {
        let s = layoutScale
        return Button {
            timerVM.start(category: cat, context: modelContext)
            selectedCategory = cat
        } label: {
            HStack(spacing: max(3, 4 * s)) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 11 * s))
                    .foregroundStyle(Color(hex: cat.colorHex))
                    .frame(width: 14 * s)

                Text(cat.name)
                    .font(.system(size: 10 * s))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatTotal(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }
}
```

- [ ] **Step 2: Verify target membership**

Ensure only `HaoTimeWatch` target is checked.

- [ ] **Step 3: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTimeWatch/WatchMainView.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: add WatchMainView with ring and category list"
```

---

### Task 6: WatchTimerView — Timer + STOP

**Files:**
- Create: `HaoTimeWatch/WatchTimerView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI
import SwiftData

struct WatchTimerView: View {
    let category: Category
    let timerVM: TimerViewModel
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutScale) private var layoutScale

    var body: some View {
        let s = layoutScale
        VStack(spacing: 12 * s) {
            Spacer()

            Image(systemName: category.iconName)
                .font(.system(size: 20 * s))
                .foregroundStyle(Color(hex: category.colorHex))

            Text(category.name)
                .font(.system(size: 13 * s, weight: .medium))
                .foregroundStyle(.primary)

            Text(timerVM.elapsedString)
                .font(.system(size: 18 * s, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: category.colorHex))

            Spacer()

            Button {
                timerVM.stop(context: modelContext)
                onDismiss()
            } label: {
                Text("STOP")
                    .font(.system(size: 13 * s, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60 * s, height: 60 * s)
                    .background(Circle().fill(.red))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 2: Verify target membership**

Ensure only `HaoTimeWatch` target is checked.

- [ ] **Step 3: Commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add HaoTimeWatch/WatchTimerView.swift
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "feat: add WatchTimerView with STOP button"
```

---

### Task 7: Build and Fix

- [ ] **Step 1: Build iOS target**

```bash
xcodebuild -project /Users/junhao/agent/Claude/Time/HaoTime/HaoTime.xcodeproj \
  -scheme HaoTime \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 2: Build watchOS target**

```bash
xcodebuild -project /Users/junhao/agent/Claude/Time/HaoTime/HaoTime.xcodeproj \
  -scheme HaoTimeWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' \
  build 2>&1 | grep -E "error:|BUILD"
```

Expected: BUILD SUCCEEDED (or note any missing target membership issues).

- [ ] **Step 3: Fix any compilation errors**

If build fails, check:
- All shared files have correct target membership
- `import SwiftData` is present where `FetchDescriptor` or `ModelContext` is used
- `TimerViewModel.swift` has the new methods
- File paths match Xcode group structure

- [ ] **Step 4: Final commit**

```bash
git -C /Users/junhao/agent/Claude/Time/HaoTime add -A
git -C /Users/junhao/agent/Claude/Time/HaoTime commit -m "fix: resolve watchOS build issues"
```
