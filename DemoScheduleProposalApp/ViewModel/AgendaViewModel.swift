import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AgendaViewModel {
    private(set) var isSelecting = false
    var selection: Set<ProposalInterval.ID> = []
    var request: ProposalRequest?
    var showsCompletionError = false

    private(set) var days: [ScheduleDay] = []
    private(set) var daysByDate: [Date: AgendaDayContent] = [:]
    private(set) var intervals: [ProposalInterval] = []
    private(set) var intervalsByDestination: [AgendaSelectionID: ProposalInterval] = [:]
    private var intervalIDs: Set<ProposalInterval.ID> = []
    private var input: AgendaInput?

    /// Display grouping never determines which events participate in proposal calculation.
    func update(events: [ScheduleEvent], now: Date, calendar: Calendar = .current) {
        let nextInput = AgendaInput(events: events, now: now, calendar: calendar)
        guard input != nextInput else { return }
        input = nextInput
        days = ScheduleDay.upcoming(events, now: now, calendar: calendar)
        intervals = ProposalInterval.available(events: events, now: now)
        intervalIDs = Set(intervals.map(\.id))
        intervalsByDestination = Dictionary(uniqueKeysWithValues: intervals.map { ($0.to.id, $0) })
        daysByDate = Dictionary(uniqueKeysWithValues: days.map { day in
            (day.date, AgendaDayContent(day: day, now: now, calendar: calendar,
                                       intervalsByDestination: intervalsByDestination))
        })
        selection.formIntersection(intervalIDs)
    }

    var validSelection: Set<ProposalInterval.ID> {
        selection.intersection(intervalIDs)
    }

    func toggleCompletion(
        _ event: ScheduleEvent, in context: ModelContext,
        saveChanges: (ModelContext) throws -> Void = { try $0.save() }
    ) {
        event.isCompleted.toggle()
        do {
            try saveChanges(context)
            if event.isCompleted {
                selection = []
            }
        } catch {
            context.rollback()
            showsCompletionError = true
        }
    }

    func beginSelection() {
        selection = []
        isSelecting = true
    }

    func cancelSelection() {
        isSelecting = false
        selection = []
    }

    func execute() {
        let selected = intervals.filter { selection.contains($0.id) }
        guard !selected.isEmpty else { return }
        request = ProposalRequest(intervals: selected)
    }
}
