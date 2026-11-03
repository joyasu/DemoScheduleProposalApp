//
//  Fixtures.swift
//  DemoScheduleProposalApp
//

//
//  各テストで使用する予定、場所、日時などの独立したテストデータを生成する。

import Foundation
import CoreLocation
import Testing
@testable import DemoScheduleProposalApp

/// Return fresh model instances so parallel tests never edit shared fixtures.
@MainActor
enum Fixtures {
    static let now = Date(timeIntervalSince1970: TestData.Time.epoch)

    static func date(
        _ components: DateComponents = TestData.Dates.today,
        hour: Int? = nil,
        calendar: Calendar = .current
    ) throws -> Date {
        var components = components
        if let hour { components.hour = hour }
        return try #require(calendar.date(from: components))
    }

    static func event(
        _ title: String = TestData.Text.title,
        start: TimeInterval = TestData.Time.tenMinutes,
        end: TimeInterval = TestData.Time.twentyMinutes,
        allDay: Bool = false,
        completed: Bool = false
    ) -> ScheduleEvent {
        let event = ScheduleEvent(
            title: title, start: now.addingTimeInterval(start), end: now.addingTimeInterval(end),
            isAllDay: allDay, memo: TestData.Text.memo
        )
        event.isCompleted = completed
        return event
    }

    static func location(_ name: String = TestData.Text.location) -> EventLocation {
        EventLocation(name: name, address: TestData.Text.address,
                      latitude: TestData.Location.latitude, longitude: TestData.Location.longitude)
    }

    static func proposal(
        _ title: String = TestData.Text.title,
        start: TimeInterval = TestData.Time.origin,
        end: TimeInterval = TestData.Time.tenMinutes
    ) -> ProposalEvent {
        let event = event(title, start: start, end: end)
        event.location = location(title)
        return ProposalEvent(event)
    }

    static func interval(from: ProposalEvent? = nil, to: ProposalEvent) -> ProposalInterval {
        ProposalInterval(from: from, to: to, start: from?.end ?? now)
    }

    static func position(
        age: TimeInterval = TestData.Time.origin,
        accuracy: CLLocationAccuracy = TestData.Location.accuracy
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: TestData.Location.latitude, longitude: TestData.Location.longitude
            ),
            altitude: TestData.Location.altitude, horizontalAccuracy: accuracy,
            verticalAccuracy: TestData.Location.verticalAccuracy,
            timestamp: now.addingTimeInterval(-age)
        )
    }

    static var invalidEventLocations: [EventLocation?] {
        [
            nil, EventLocation(name: "名前だけ"),
            EventLocation(name: "緯度のみ", latitude: 35),
            EventLocation(name: "経度のみ", longitude: 139),
            EventLocation(name: "範囲外", latitude: 91, longitude: 139),
            EventLocation(name: "範囲外", latitude: 35, longitude: 181)
        ]
    }

    static var invalidRouteLocations: [EventLocation?] {
        [
            nil, EventLocation(name: "名前だけ"),
            EventLocation(name: "範囲外", latitude: 100, longitude: 139)
        ]
    }
}
