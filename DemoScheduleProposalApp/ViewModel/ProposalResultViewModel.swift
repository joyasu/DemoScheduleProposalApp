//
//  ProposalResultViewModel.swift
//  DemoScheduleProposalApp
//

//
//  提案に必要な場所や現在地を補完し、提案の取得状態と結果を管理する。

import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class ProposalResultViewModel {
    let request: ProposalRequest
    private var locations: [AgendaSelectionID: EventLocation] = [:]

    func resolved(_ event: ProposalEvent) -> ProposalEvent {
        var result = event
        result.location = locations[event.id] ?? event.location
        return result
    }

    func needsLocation(_ event: ProposalEvent) -> Bool {
        guard let location = resolved(event).location,
              let latitude = location.latitude, let longitude = location.longitude else { return true }
        return !CLLocationCoordinate2DIsValid(.init(latitude: latitude, longitude: longitude))
    }

    func setLocation(_ location: EventLocation, for event: ProposalEvent) {
        locations[event.id] = location
        attempt += 1
    }

    private(set) var gaps: [ProposalInterval.ID: ProposalGap] = [:]
    private(set) var isLoading = true
    var attempt = 0
    private(set) var currentOrigin: ProposalEvent?
    private(set) var locationError: String?

    private let currentLocation: @MainActor () async throws -> EventLocation
    private let makeGap: @MainActor (ProposalEvent, ProposalEvent) async throws -> ProposalGap
    private var loadID = UUID()

    private let now: @MainActor () -> Date

    init(
        request: ProposalRequest,
        currentLocation: @escaping @MainActor () async throws -> EventLocation = {
            try await CurrentLocationService().currentLocation()
        },
        makeGap: @escaping @MainActor (ProposalEvent, ProposalEvent) async throws -> ProposalGap = {
            try await ProposalService().makeGap(from: $0, to: $1)
        },
        now: @escaping @MainActor () -> Date = { .now }
    ) {
        self.request = request
        self.currentLocation = currentLocation
        self.makeGap = makeGap
        self.now = now
    }

    func load() async {
        let id = UUID()
        loadID = id
        isLoading = true
        gaps = [:]
        currentOrigin = nil
        locationError = nil
        defer {
            if loadID == id { isLoading = false }
        }
        if request.intervals.contains(where: { $0.from == nil }) {
            do {
                let location = try await currentLocation()
                try Task.checkCancellation()
                guard loadID == id else { return }
                let origin = ProposalEvent(now: now(), location: location)
                currentOrigin = origin
            } catch {
                guard !Task.isCancelled, loadID == id else { return }
                guard !(error is CancellationError) else { return }
                locationError = error.localizedDescription
            }
        }
        for interval in request.intervals {
            guard !Task.isCancelled, loadID == id else { return }
            guard let from = interval.from ?? currentOrigin else { continue }
            do {
                let gap = try await makeGap(resolved(from), resolved(interval.to))
                try Task.checkCancellation()
                guard loadID == id else { return }
                gaps[interval.id] = gap
            } catch {
                guard !Task.isCancelled, !(error is CancellationError), loadID == id else { return }
                gaps[interval.id] = .unavailable(.unexpectedFailure)
            }
        }
    }
}
