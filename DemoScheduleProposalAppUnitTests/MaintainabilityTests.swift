//
//  MaintainabilityTests.swift
//  DemoScheduleProposalApp
//

//
//  予定一覧の更新、カレンダー管理、共通モデルの整合性を検証するテスト。

import Foundation
import SwiftData
import Testing
@testable import DemoScheduleProposalApp

@Suite(.timeLimit(.minutes(TestData.suiteTimeoutMinutes)))
@MainActor
struct MaintainabilityTests {
    // MAINT-001: Raw events drive proposals independently of multi-day display expansion.
    @Test func agendaUpdatesSnapshotsAndPreparedRows() throws {
        let now = try Fixtures.date()
        let calendar = Calendar.current
        let allDay = Fixtures.event(allDay: true)
        allDay.start = now
        allDay.end = try Fixtures.date(TestData.Dates.allDayEnd)
        let next = Fixtures.event()
        next.start = now.addingTimeInterval(TestData.Time.oneHour)
        next.end = next.start.addingTimeInterval(TestData.Time.oneHour)
        let model = AgendaViewModel()
        model.update(events: [allDay, next], now: now, calendar: calendar)
        #expect(model.days.count == TestData.Count.triple)
        #expect(model.intervals.count == TestData.Count.single)
        let interval = try #require(model.intervals.first)
        #expect(interval.from == nil && interval.to.id == .event(next.persistentModelID))
        let today = try #require(model.daysByDate[calendar.startOfDay(for: now)])
        #expect(today.rows.map(\.id) == [.event(.event(allDay.persistentModelID)), .now, .event(.event(next.persistentModelID))])
        #expect(today.selectionRows.map(\.id) == [
            .event(.event(allDay.persistentModelID)), .now, .interval(interval.id), .event(.event(next.persistentModelID))
        ])

        // Editing a reference object without changing its ID must invalidate the cached snapshot.
        model.selection = [interval.id]
        next.title = TestData.Text.updated
        next.location = Fixtures.location()
        model.update(events: [allDay, next], now: now, calendar: calendar)
        model.execute()
        #expect(model.request?.intervals.first?.to.title == TestData.Text.updated)
        #expect(model.request?.intervals.first?.to.location == next.location)
        next.start = now.addingTimeInterval(-TestData.Time.oneMinute)
        model.update(events: [allDay, next], now: now, calendar: calendar)
        #expect(model.intervals.isEmpty && model.validSelection.isEmpty)
        let ongoing = try #require(model.daysByDate[calendar.startOfDay(for: now)])
        #expect(!ongoing.rows.contains { $0.id == .now })
    }

    // MAINT-002: Empty navigation history is bounded; scheduled weeks are never evicted.
    @Test func calendarBoundsHistoryAndRetainsScheduledDates() throws {
        let now = try Fixtures.date()
        let calendar = Calendar.current
        let scheduled = try Fixtures.date(TestData.Dates.yesterday)
        let model = AgendaCalendarViewModel(now: now, calendar: calendar)
        model.update(scheduledDates: [scheduled], now: now, calendar: calendar)
        for _ in 0..<(AgendaCalendarViewModel.maximumBrowsedWeeks * TestData.Count.pair) {
            model.changeWeek(by: TestData.Dates.sameDayOffset + TestData.Dates.consecutiveDays)
        }
        #expect(model.displayDates.contains(calendar.startOfDay(for: scheduled)))
        #expect(model.displayDates.contains(calendar.startOfDay(for: now)))
        #expect(model.weekDates.allSatisfy { model.displayDates.contains($0) })
        #expect(model.displayDates.count <= (AgendaCalendarViewModel.maximumBrowsedWeeks + TestData.Count.pair) * TestData.Dates.daysPerWeek)
        let firstBrowsed = try #require(calendar.date(byAdding: .day, value: TestData.Dates.daysPerWeek, to: now))
        #expect(!model.displayDates.contains(calendar.startOfDay(for: firstBrowsed)))
    }

    // MAINT-003: One injected calendar governs editing, saving, grouping and week generation.
    @Test(arguments: TestData.Dates.timeZones)
    func allDayRoundTripUsesInjectedCalendar(timeZone: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        calendar.firstWeekday = TestData.Dates.consecutiveDays // App policy still starts on Monday.
        let start = try Fixtures.date(TestData.Dates.yesterday, calendar: calendar)
        let end = try Fixtures.date(TestData.Dates.tomorrow, calendar: calendar)
        var draft = EventDraft(now: start)
        draft.title = TestData.Text.allDay
        draft.isAllDay = true
        draft.start = start
        draft.end = end
        let editor = EventEditorViewModel(draft: draft, calendar: calendar)
        let context = try Fixtures.context()
        #expect(editor.save(in: context))
        let event = try #require(Fixtures.fetch(ModelContext(context.container)).first)
        #expect(event.start == calendar.startOfDay(for: start))
        #expect(event.end == calendar.startOfDay(for: end))
        let agenda = AgendaViewModel()
        agenda.update(events: [event], now: start, calendar: calendar)
        let expected = try TestData.Dates.expectedAllDayDates.map {
            calendar.startOfDay(for: try Fixtures.date($0, calendar: calendar))
        }
        #expect(agenda.days.map(\.date) == expected)
        let week = AgendaCalendarViewModel.week(containing: end, calendar: calendar)
        #expect(calendar.component(.weekday, from: try #require(week.first)) == TestData.Dates.mondayWeekday)
        #expect(week.contains(calendar.startOfDay(for: end)))

        let shifted = try Fixtures.date(TestData.Dates.shiftedStart, calendar: calendar)
        editor.start = shifted
        #expect(calendar.dateComponents([.day], from: editor.start, to: editor.end).day == TestData.Dates.allDayDuration)
    }

    // MAINT-004: Calendar changes rebuild cached midnight keys.
    @Test func calendarChangeRebuildsDateKeys() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: TestData.Dates.timeZones[0]))
        var losAngeles = tokyo
        losAngeles.timeZone = try #require(TimeZone(identifier: TestData.Dates.timeZones[1]))
        let now = Fixtures.now
        let model = AgendaCalendarViewModel(now: now, calendar: tokyo)
        model.update(scheduledDates: [], now: now, calendar: tokyo)
        let oldDates = model.displayDates
        model.update(scheduledDates: [], now: now, calendar: losAngeles)
        #expect(model.displayDates != oldDates)
        #expect(model.displayDates.allSatisfy { $0 == losAngeles.startOfDay(for: $0) })
        #expect(model.displayDates.contains(losAngeles.startOfDay(for: now)))
    }

    // MAINT-005: A rest cannot hold reversed endpoints; invalid travel cannot produce a plan.
    @Test(arguments: TestData.Search.invalidDurations)
    func typedResultsRejectInvalidIntervals(duration: Double) {
        #expect(ProposalGap.Rest(start: Fixtures.now, end: Fixtures.now.addingTimeInterval(-TestData.Time.oneMinute),
                                 locationName: nil) == nil)
        let gap = ProposalGap.planned(from: Fixtures.proposal(), to: Fixtures.proposal(start: TestData.Time.oneHour),
                                      duration: duration)
        #expect(gap == .unavailable(.invalidTravelTime))
    }

    // MAINT-006: Ordinary dependency errors are visible per interval and do not abort later intervals.
    @Test func proposalFailureContinuesWithNextInterval() async {
        let first = Fixtures.proposal()
        let middle = Fixtures.proposal(TestData.Text.next, start: TestData.Time.oneHour, end: TestData.Time.oneHour)
        let last = Fixtures.proposal(TestData.Text.other, start: TestData.Time.twoHours)
        let intervals = [Fixtures.interval(from: first, to: middle), Fixtures.interval(from: middle, to: last)]
        var calls = 0
        let model = ProposalResultViewModel(request: ProposalRequest(intervals: intervals), makeGap: { _, _ in
            calls += 1
            if calls == TestData.Count.single { throw TestFailure.injected }
            return .unavailable(.missingLocation)
        })
        await model.load()
        #expect(calls == TestData.Count.pair)
        #expect(model.gaps[intervals[0].id] == .unavailable(.unexpectedFailure))
        #expect(model.gaps[intervals[1].id] == .unavailable(.missingLocation))
        #expect(!model.isLoading)
    }

    // MAINT-007: CancellationError remains cancellation even if the dependency throws it directly.
    @Test func proposalCancellationDoesNotBecomeFailure() async {
        let interval = Fixtures.interval(from: Fixtures.proposal(), to: Fixtures.proposal(start: TestData.Time.oneHour))
        let model = ProposalResultViewModel(request: ProposalRequest(intervals: [interval]), makeGap: { _, _ in
            throw CancellationError()
        })
        await model.load()
        #expect(model.gaps.isEmpty && !model.isLoading)
    }

    // MAINT-008: Late cleanup from an old load cannot end a newer load's progress state.
    @Test func supersededLoadCannotClearLoadingState() async {
        let interval = Fixtures.interval(from: Fixtures.proposal(), to: Fixtures.proposal(start: TestData.Time.oneHour))
        let firstGate = TestGate<ProposalGap>()
        let secondGate = TestGate<ProposalGap>()
        var calls = 0
        let model = ProposalResultViewModel(request: ProposalRequest(intervals: [interval]), makeGap: { _, _ in
            calls += 1
            return try await (calls == TestData.Count.single ? firstGate : secondGate).wait()
        })
        let first = Task { await model.load() }
        await firstGate.started.wait()
        first.cancel()
        let second = Task { await model.load() }
        await secondGate.started.wait()
        firstGate.resolve(.success(.unavailable(.routeUnavailable)))
        await first.value
        #expect(model.isLoading && model.gaps.isEmpty)
        secondGate.resolve(.success(.unavailable(.missingLocation)))
        await second.value
        #expect(!model.isLoading && model.gaps[interval.id] == .unavailable(.missingLocation))
    }
}
