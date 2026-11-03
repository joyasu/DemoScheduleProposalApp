import Foundation
import SwiftData
import CoreLocation
import Testing
@testable import DemoScheduleProposalApp

enum TestFailure: Error {
    case injected
}

@MainActor
extension Fixtures {
    static func context() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ScheduleEvent.self, configurations: configuration)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    static func fetch(_ context: ModelContext) throws -> [ScheduleEvent] {
        try context.fetch(FetchDescriptor<ScheduleEvent>(sortBy: [SortDescriptor(\.start)]))
    }

}

/// Explicit handshakes keep asynchronous tests independent of scheduler timing.
@MainActor
final class TestSignal {
    private var signaled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func signal() {
        signaled = true
        let pending = waiters
        waiters = []
        for waiter in pending { waiter.resume() }
    }

    func wait() async {
        guard !signaled else { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}

/// Models an external operation that may finish after its caller is cancelled.
@MainActor
final class TestGate<Value> {
    let started = TestSignal()
    private var continuation: CheckedContinuation<Value, Error>?

    func wait() async throws -> Value {
        try await withCheckedThrowingContinuation {
            continuation = $0
            started.signal()
        }
    }

    func resolve(_ result: Result<Value, Error>) {
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}

@MainActor
final class FakeLocationManager: CurrentLocationManaging {
    weak var delegate: (any CLLocationManagerDelegate)?
    var desiredAccuracy: CLLocationAccuracy = 0
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var authorizationRequests = 0
    var locationRequests = 0
    var onRequest: (() -> Void)?
    var stops = 0
    let requested = TestSignal()
    let authorizationRequested = TestSignal()
    // Used only as the delegate callback's sender; no real location request is made.
    private let sender = CLLocationManager()

    func requestWhenInUseAuthorization() {
        authorizationRequests += 1
        authorizationRequested.signal()
    }

    func requestLocation() {
        locationRequests += 1
        requested.signal()
        onRequest?()
    }

    func stopUpdatingLocation() { stops += 1 }

    func authorize(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        delegate?.locationManagerDidChangeAuthorization?(sender)
    }

    func deliver(_ locations: [CLLocation]) {
        delegate?.locationManager?(sender, didUpdateLocations: locations)
    }

    func fail() {
        delegate?.locationManager?(sender, didFailWithError: TestFailure.injected)
    }
}
