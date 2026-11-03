import Foundation
import Observation
import MapKit

@MainActor
@Observable
final class LocationPickerViewModel {
    var query = ""
    var results: [EventLocation] = []
    var isSearching = false
    var message = ""
    var searchText: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private let searchLocations: @MainActor (String) async throws -> [EventLocation]
    private let debounce: @MainActor () async throws -> Void

    init(
        searchLocations: @escaping @MainActor (String) async throws -> [EventLocation] = LocationPickerViewModel.liveSearch,
        debounce: @escaping @MainActor () async throws -> Void = {
            try await Task.sleep(for: .milliseconds(600))
        }
    ) {
        self.searchLocations = searchLocations
        self.debounce = debounce
    }

    func search(_ text: String) async {
        results = []
        message = ""
        isSearching = false
        guard !text.isEmpty else { return }
        isSearching = true
        do {
            // Debounce input; cancellation prevents stale results replacing new ones.
            try await debounce()
            try Task.checkCancellation()
            let locations = try await searchLocations(text)
            try Task.checkCancellation()
            results = locations
            if results.isEmpty {
                message = "見つかりませんでした。別の名前で検索するか、自由入力で設定できます。"
            }
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            isSearching = false
            message = "検索できませんでした。通信環境を確認して入力し直すか、自由入力をご利用ください。"
        }
    }

    private static func liveSearch(_ text: String) async throws -> [EventLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = [.address, .pointOfInterest]
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map { item in
            if #available(iOS 26.0, macOS 26.0, *) {
                return EventLocation(
                    name: item.name ?? text,
                    address: item.address?.fullAddress,
                    latitude: item.location.coordinate.latitude,
                    longitude: item.location.coordinate.longitude
                )
            } else {
                return EventLocation(
                    name: item.name ?? text,
                    address: item.placemark.title,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
        }
    }
}
