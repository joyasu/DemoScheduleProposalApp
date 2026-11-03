//
//  ProposalService.swift
//  DemoScheduleProposalApp
//

//
//  車の経路検索で所要時間を取得し、予定間の移動と休憩を提案する。

import Foundation
import MapKit

@MainActor
struct ProposalService {
    private let calculateETA: @MainActor (MKDirections.Request) async throws -> TimeInterval

    init(calculateETA: @escaping @MainActor (MKDirections.Request) async throws -> TimeInterval = Self.liveETA) {
        self.calculateETA = calculateETA
    }

    private static func liveETA(_ request: MKDirections.Request) async throws -> TimeInterval {
        let directions = MKDirections(request: request)
        do {
            return try await directions.calculateETA().expectedTravelTime
        } catch {
            if Task.isCancelled { directions.cancel() }
            throw error
        }
    }

    func makeGap(from: ProposalEvent, to: ProposalEvent) async throws -> ProposalGap {
        guard from.end <= to.start else {
            return .unavailable(.overlappingEvents)
        }
        guard let source = mapItem(from.location), let destination = mapItem(to.location) else {
            return .unavailable(.missingLocation)
        }
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        request.departureDate = from.end
        do {
            try Task.checkCancellation()
            let duration = try await calculateETA(request)
            try Task.checkCancellation()
            guard duration.isFinite, duration >= 0 else {
                return .unavailable(.invalidTravelTime)
            }
            return ProposalGap.planned(from: from, to: to, duration: duration)
        } catch {
            if Task.isCancelled || error is CancellationError { throw CancellationError() }
            return .unavailable(.routeUnavailable)
        }
    }

    private func mapItem(_ location: EventLocation?) -> MKMapItem? {
        guard let location, let latitude = location.latitude, let longitude = location.longitude,
              CLLocationCoordinate2DIsValid(.init(latitude: latitude, longitude: longitude)) else { return nil }
        let item: MKMapItem
        if #available(iOS 26.0, macOS 26.0, *) {
            item = MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        } else {
            item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: latitude, longitude: longitude)))
        }
        item.name = location.name
        return item
    }
}
