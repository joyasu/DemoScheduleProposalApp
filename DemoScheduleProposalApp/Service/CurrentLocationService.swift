import Foundation
import CoreLocation

@MainActor
protocol CurrentLocationManaging: AnyObject {
    var delegate: (any CLLocationManagerDelegate)? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    func requestLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: CurrentLocationManaging {}

@MainActor
final class CurrentLocationService: NSObject, CLLocationManagerDelegate {
    private let manager: any CurrentLocationManaging
    private let now: @MainActor () -> Date
    private let waitForTimeout: @MainActor () async throws -> Void
    private var continuation: CheckedContinuation<EventLocation, Error>?
    private var timeout: Task<Void, Never>?

    init(
        manager: any CurrentLocationManaging = CLLocationManager(),
        now: @escaping @MainActor () -> Date = { .now },
        waitForTimeout: @escaping @MainActor () async throws -> Void = {
            try await Task.sleep(for: .seconds(30))
        }
    ) {
        self.manager = manager
        self.now = now
        self.waitForTimeout = waitForTimeout
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async throws -> EventLocation {
        try Task.checkCancellation()
        // A service instance can only own one pending location request.
        guard continuation == nil else { throw CurrentLocationError.unavailable }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                timeout = Task { [weak self, waitForTimeout] in
                    do {
                        try await waitForTimeout()
                        try Task.checkCancellation()
                        self?.finish(.failure(CurrentLocationError.unavailable))
                    } catch {}
                }
                requestIfAuthorized()
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finish(.failure(CancellationError()))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        requestIfAuthorized()
    }

    private func requestIfAuthorized() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(CurrentLocationError.denied))
        @unknown default:
            finish(.failure(CurrentLocationError.unavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSince(now())) < 120 else {
            finish(.failure(CurrentLocationError.unavailable))
            return
        }
        finish(.success(EventLocation(name: "現在地",
                                      latitude: location.coordinate.latitude,
                                      longitude: location.coordinate.longitude)))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(CurrentLocationError.unavailable))
    }

    private func finish(_ result: Result<EventLocation, Error>) {
        timeout?.cancel()
        timeout = nil
        manager.stopUpdatingLocation()
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}
