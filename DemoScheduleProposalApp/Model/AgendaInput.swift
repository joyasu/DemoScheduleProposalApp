import Foundation
import SwiftData

/// Value snapshots detect edits to SwiftData objects, including edits that retain their IDs.
struct AgendaInput: Equatable {
    struct Event: Equatable {
        let id: PersistentIdentifier
        let title: String
        let start: Date
        let end: Date
        let isAllDay: Bool
        let isCompleted: Bool
        let location: EventLocation?
        let memo: String

        init(_ event: ScheduleEvent) {
            id = event.persistentModelID
            title = event.title
            start = event.start
            end = event.end
            isAllDay = event.isAllDay
            isCompleted = event.isCompleted
            location = event.location
            memo = event.memo
        }
    }

    let events: [Event]
    let now: Date
    let calendar: Calendar

    init(events: [ScheduleEvent], now: Date, calendar: Calendar) {
        self.events = events.map(Event.init)
        self.now = now
        self.calendar = calendar
    }
}
