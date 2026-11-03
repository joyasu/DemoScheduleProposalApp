import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class EventEditorViewModel {
    var draft: EventDraft
    var showsSaveError = false
    private(set) var calendar: Calendar

    init(draft: EventDraft, calendar: Calendar = .current) {
        self.draft = draft
        self.calendar = calendar
    }

    func updateCalendar(_ calendar: Calendar) {
        self.calendar = calendar
    }

    var start: Date {
        get { draft.start }
        set { updateDate(newValue, isStart: true) }
    }

    var end: Date {
        get { draft.end }
        set { updateDate(newValue, isStart: false) }
    }

    private func updateDate(_ date: Date, isStart: Bool) {
        let previousStart = draft.start
        let previousEnd = draft.end
        if isStart {
            draft.start = date
        } else {
            draft.end = date
        }

        if draft.isAllDay {
            let startDay = calendar.startOfDay(for: draft.start)
            let endDay = calendar.startOfDay(for: draft.end)
            guard startDay > endDay else { return }
            let days = max(0, calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: previousStart),
                to: calendar.startOfDay(for: previousEnd)
            ).day ?? 0)
            if isStart {
                draft.end = calendar.date(byAdding: .day, value: days, to: date) ?? date
            } else {
                draft.start = calendar.date(byAdding: .day, value: -days, to: date) ?? date
            }
        } else {
            guard draft.start > draft.end else { return }
            // Keep the edited endpoint and shift the other by the previous duration.
            let duration = max(0, previousEnd.timeIntervalSince(previousStart))
            if isStart {
                draft.end = date.addingTimeInterval(duration)
            } else {
                draft.start = date.addingTimeInterval(-duration)
            }
        }
    }

    var showsInvalidDates: Bool {
        !isValid && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (draft.isAllDay
         ? calendar.startOfDay(for: draft.end) >= calendar.startOfDay(for: draft.start)
         : draft.end >= draft.start)
    }

    func save(in context: ModelContext, saveChanges: (ModelContext) throws -> Void = { try $0.save() }) -> Bool {
        guard isValid else { return false }
        let start = draft.isAllDay ? calendar.startOfDay(for: draft.start) : draft.start
        let end = draft.isAllDay ? calendar.startOfDay(for: draft.end) : draft.end
        let event = draft.event ?? ScheduleEvent(title: "", start: start, end: end, isAllDay: false, memo: "")
        if draft.event == nil { context.insert(event) }
        event.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.start = start
        event.end = end
        event.isAllDay = draft.isAllDay
        event.location = draft.location
        event.memo = draft.memo
        return persist(in: context, saveChanges: saveChanges)
    }

    func delete(in context: ModelContext, saveChanges: (ModelContext) throws -> Void = { try $0.save() }) -> Bool {
        guard let event = draft.event else { return false }
        context.delete(event)
        return persist(in: context, saveChanges: saveChanges)
    }

    private func persist(in context: ModelContext, saveChanges: (ModelContext) throws -> Void) -> Bool {
        do {
            try saveChanges(context)
            return true
        } catch {
            context.rollback()
            showsSaveError = true
            return false
        }
    }
}
