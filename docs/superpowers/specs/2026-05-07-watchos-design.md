# watchOS HaoTime Design Spec

## Overview

Add a watchOS target to HaoTime. Two screens: today glance (ring + category list) and timer (stopwatch + STOP button). Data persistence via CloudKit (SwiftData), real-time state sync via WatchConnectivity.

## Feature Scope

- **Today Ring + Category List** — ring shows today's time distribution by category color, center shows total hours. Category icons + names on the right, tappable.
- **Quick Start/Stop Timer** — tap a category → animated transition to timer screen. Large STOP button. Timer runs locally, syncs start/stop state to iPhone via WCS.
- **No** week history, no session editing, no complication (future).

## Architecture

```
WatchConnectivity (real-time start/stop messages)
     Watch ◀──────────────────────▶ iPhone

CloudKit / SwiftData (persistent: Session, Category)
     Watch ◀────── iCloud ────────▶ iPhone
```

### Data Flow

1. Watch taps category → local `TimerViewModel.start()` → WCS sends `{action:"start", categoryID, startTime}` → iPhone TimerBar shows running state
2. iPhone taps stop → WCS sends `{action:"stop"}` → Watch dismisses timer, returns to main screen
3. Watch taps STOP → local stop → WCS sends `{action:"stop"}` → iPhone TimerBar clears
4. Session written to CloudKit by either side, auto-syncs within seconds

## Screens

### WatchMainView (Page 1)

```
┌──────────────────┐
│  ╭─────╮   ✏️ 写作│
│ ╱       ╲  🧠 思考│   RingView(size: ~55, lineWidth: computed)
││  4h30m  │  🏃 运动│   center text: total hours (8pt scaled)
│ ╲       ╱  ✓ 杂事│   category list: icon + name, tappable
│  ╰─────╯         │
└──────────────────┘
```

- HStack: RingView(left) + VStack of category rows(right)
- Category row: SF Symbol (category.iconName) + Text(category.name)
- onTap category → navigate to WatchTimerView
- Uses shared DataViewModel for aggregation
- Watches TimerViewModel.isRunning to handle remote stop

### WatchTimerView (Page 2)

```
┌──────────────────┐
│  ✏️ 写作          │
│  00:15:32        │
│                  │
│     ╭─────╮      │
│     │ STOP │      │   Circle, fill: red, ~60pt
│     ╰─────╯      │
└──────────────────┘
```

- Top: category icon + name
- Middle: elapsed time in monospace font
- Bottom: large red STOP circle
- STOP → timerVM.stop() → WC send stop → dismiss → back to WatchMainView

## Files

### New (watchOS target)

| File | Purpose |
|------|---------|
| `HaoTimeWatchApp.swift` | @main entry, ModelContainer with CloudKit |
| `WatchMainView.swift` | Page 1: ring + category list |
| `WatchTimerView.swift` | Page 2: timer + STOP |

### New (Shared)

| File | Purpose |
|------|---------|
| `WatchConnectivityManager.swift` | Singleton WCSession manager, sends/receives start/stop messages |

### Modified

| File | Change |
|------|--------|
| `HaoTimeApp.swift` (iOS) | +1 line: `.onAppear { WatchConnectivityManager.shared.activate() }` |
| `TimerViewModel.swift` | After start/stop: call `WatchConnectivityManager.shared.send(action:)` |

### Reused (no changes)

| File | Why |
|------|-----|
| `Category.swift` | Same model |
| `Session.swift` | Same model |
| `DataViewModel.swift` | Same aggregation logic |
| `RingView.swift` | Same ring rendering |
| `LayoutScale.swift` | Same scaling helper |

## WCS Message Protocol

```swift
enum WCSAction: Codable {
    case start(categoryID: String, startTime: Date)
    case stop
}
```

Sent as dictionary via `WCSession.sendMessage()` for real-time delivery.

## watchOS Target Setup

- iOS App with Watch App target in Xcode
- Watch app bundle ID: `<ios-bundle-id>.watchkitapp`
- Shared app group for framework access
- Models, ViewModels, Helpers, WCSManager — shared across iOS/watchOS targets
- Views — watch-specific views in watchOS target folder

## Constraints

- No changes to macOS/iOS UI files (ListView, TimerBar, DayDetailView, RingView, BarChartView, WeekView, DayColumn, DaySessionsView, CategorySessionsView, SessionEditView, SettingsView)
- No changes to existing SwiftUI view code
- TimerViewModel changes limited to WCS notification calls (no logic changes)
- HaoTimeApp.swift: 1 line addition only
