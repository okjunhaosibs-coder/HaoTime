#if os(iOS)
import HealthKit
#endif
import Foundation

#if os(iOS)
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private var authorized = false
    var onWorkoutDataChanged: (() -> Void)?

    private init() {}

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: typesToRead)
            authorized = true
            startWorkoutObserver()
        } catch {
            print("[HealthKit] Auth error: \(error.localizedDescription)")
        }
    }

    private func startWorkoutObserver() {
        let workoutType = HKObjectType.workoutType()
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            if error == nil {
                DispatchQueue.main.async { self?.onWorkoutDataChanged?() }
            }
            completionHandler()
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }

    func fetchTodayWorkouts() async -> [HKWorkout] {
        guard authorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 0)
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: combined,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    print("[HealthKit] Query error: \(error.localizedDescription)")
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }
}
#endif
