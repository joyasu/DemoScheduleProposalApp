import Foundation
import SwiftData
import Testing
@testable import DemoScheduleProposalApp

@MainActor
struct ScheduleModelTests {
    // DAY-001
    // 開始直前・開始時刻・終了直前・終了時刻を比較し、開始以上かつ終了未満の範囲だけ進行中となることを確認する。
    @Test(arguments: TestData.Schedule.ongoingOffsets)
    func ongoingBoundaries(offset: Double) {
        let event = Fixtures.event(start: TestData.Time.origin, end: TestData.Time.tenMinutes)
        #expect(event.isOngoing(at: Fixtures.now.addingTimeInterval(offset)) == (offset >= TestData.Time.origin && offset < TestData.Time.tenMinutes))
    }

    // DAY-002
    // 時刻が予定の範囲内でも、完了済み予定と終日予定は進行中として扱われないことを確認する。
    @Test(arguments: TestData.booleanCases)
    func completedAndAllDayAreNotOngoing(allDay: Bool) {
        let event = Fixtures.event(start: -TestData.Time.tenMinutes, end: TestData.Time.tenMinutes, allDay: allDay, completed: !allDay)
        #expect(!event.isOngoing(at: Fixtures.now))
    }

    // DAY-003, DAY-004, DAY-005, DAY-007
    // 順不同の予定を日付順にまとめ、過去の予定を保持しつつ前日開始の進行中予定を今日へ配置することを確認する。
    // 同日の終日優先・開始時刻順の並びと、入力が空なら結果も空になることも確認する。
    @Test func groupingRetainsPastAndMovesOngoingEventsToToday() throws {
        let calendar = Calendar.current
        let now = try Fixtures.date()
        let yesterday = try Fixtures.date(TestData.Dates.yesterday)
        let tomorrow = try Fixtures.date(TestData.Dates.tomorrow)
        let past = Fixtures.event(TestData.Text.past)
        past.start = yesterday
        past.end = yesterday.addingTimeInterval(TestData.Time.tenMinutes)
        let ongoing = Fixtures.event(TestData.Text.ongoing)
        ongoing.start = yesterday
        ongoing.end = now.addingTimeInterval(TestData.Time.tenMinutes)
        let later = Fixtures.event(TestData.Text.future)
        later.start = tomorrow
        later.end = tomorrow.addingTimeInterval(TestData.Time.tenMinutes)
        let allDay = Fixtures.event(TestData.Text.allDay, allDay: true)
        allDay.start = now
        allDay.end = now
        let today = Fixtures.event(TestData.Text.today)
        today.start = now.addingTimeInterval(TestData.Time.twentyMinutes)
        today.end = now.addingTimeInterval(TestData.Time.thirtyMinutes)
        let groups = ScheduleDay.upcoming([later, today, ongoing, past, allDay], now: now)
        #expect(groups.map(\.date) == [yesterday, now, tomorrow].map { calendar.startOfDay(for: $0) })
        #expect(groups.map { $0.events.map(\.title) } == TestData.Schedule.groupedTitles)
        #expect(ScheduleDay.upcoming([], now: now).isEmpty)
    }

    // DAY-006: inclusive end dates and a daylight-saving transition.
    // 東京とロサンゼルスで、夏時間終了をまたぐ終日予定が開始日から終了日まで各日に配置されることを確認する。
    // 日別に展開した終日予定から、提案用の空き区間が生成されないことも確認する。
    @Test(arguments: TestData.Dates.timeZones)
    func allDayEventsAppearOnEveryDate(timeZone: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        let event = Fixtures.event(allDay: true)
        event.start = try Fixtures.date(TestData.Dates.yesterday, calendar: calendar)
        event.end = try Fixtures.date(TestData.Dates.tomorrow, calendar: calendar)
        let groups = ScheduleDay.upcoming([event], now: event.start, calendar: calendar)
        let expected = try TestData.Dates.expectedAllDayDates.map {
            try Fixtures.date($0, hour: TestData.Dates.midnight, calendar: calendar)
        }
        #expect(groups.map(\.date) == expected)
        #expect(groups.allSatisfy { $0.events.count == TestData.Count.single && $0.events.first === event })
        #expect(ProposalInterval.available(events: groups.flatMap(\.events), now: event.start).isEmpty)
    }

    // CAL-001
    // 月曜・日曜・年末・年始を含む日付から、その日を含む月曜始まりの連続7日が得られることを確認する。
    @Test(arguments: TestData.Dates.weekDates)
    func weeksStartOnMonday(parts: DateComponents) throws {
        let calendar = Calendar.current
        let date = try Fixtures.date(parts)
        let week = AgendaCalendarViewModel.week(containing: date)
        #expect(week.count == TestData.Dates.daysPerWeek)
        let first = try #require(week.first)
        #expect(calendar.component(.weekday, from: first) == TestData.Dates.mondayWeekday)
        #expect(week.contains(calendar.startOfDay(for: date)))
        for pair in zip(week, week.dropFirst()) {
            #expect(calendar.dateComponents([.day], from: pair.0, to: pair.1).day == TestData.Dates.consecutiveDays)
        }
    }

    // CAL-002, CAL-003
    // 前週・翌週へ移動した後も閲覧済みの週を保持し、今週・予定の週と合わせて重複なく日付順に表示することを確認する。
    // 予定がない日も空のグループとして含まれることを確認する。
    @Test func browsedAndScheduledWeeksRemainVisible() throws {
        let now = Calendar.current.startOfDay(for: try Fixtures.date())
        let model = AgendaCalendarViewModel(now: now)
        model.update(scheduledDates: [], now: now, calendar: .current)
        model.changeWeek(by: TestData.Dates.previousWeekOffset)
        #expect(Calendar.current.dateComponents([.day], from: now, to: model.weekDate).day == TestData.Dates.previousWeekDays)
        let priorWeek = AgendaCalendarViewModel.week(containing: model.weekDate)
        model.changeWeek(by: TestData.Dates.forwardWeekOffset)
        #expect(Calendar.current.dateComponents([.day], from: now, to: model.weekDate).day == TestData.Dates.nextWeekDays)
        let nextWeek = AgendaCalendarViewModel.week(containing: model.weekDate)
        let distant = Calendar.current.startOfDay(for: try Fixtures.date(TestData.Dates.distant))
        model.update(scheduledDates: [distant], now: now, calendar: .current)
        let expected = Set(priorWeek + nextWeek + AgendaCalendarViewModel.week(containing: now)
                           + AgendaCalendarViewModel.week(containing: distant))
        #expect(model.displayDates == expected.sorted())
        let empty = AgendaCalendarViewModel(now: now)
        empty.update(scheduledDates: [], now: now, calendar: .current)
        #expect(empty.displayDates == AgendaCalendarViewModel.week(containing: now))
    }

    // INT-001
    // 完了済み・終日・現在以前に終了した予定だけを渡した場合、および空配列の場合に、提案区間が生成されないことを確認する。
    @Test func excludedEventsDoNotProduceIntervals() {
        let events = [
            Fixtures.event(allDay: true),
            Fixtures.event(completed: true),
            Fixtures.event(start: -TestData.Time.tenMinutes, end: TestData.Time.origin),
            Fixtures.event(start: -TestData.Time.twentyMinutes, end: -TestData.Time.tenMinutes)
        ]
        #expect(ProposalInterval.available(events: events, now: Fixtures.now).isEmpty)
        #expect(ProposalInterval.available(events: [], now: Fixtures.now).isEmpty)
    }

    // INT-002
    // 次の予定まで空きがある場合、現在を開始日時とし、起点の予定を持たない区間が1件生成されることを確認する。
    @Test func firstIntervalStartsNow() throws {
        let event = Fixtures.event()
        let intervals = ProposalInterval.available(events: [event], now: Fixtures.now)
        #expect(intervals.count == TestData.Count.single)
        let interval = try #require(intervals.first)
        #expect(interval.from == nil)
        #expect(interval.start == Fixtures.now)
        #expect(interval.to.id == .event(event.persistentModelID))
    }

    // INT-003, INT-004
    // 進行中・内包・重複・隣接する予定を混在させ、占有時間の途中には区間を作らず、最後の終了から次の予定までだけを提案することを確認する。
    @Test func overlappingAndAdjacentEventsUseLatestEnd() throws {
        let ongoing = Fixtures.event(TestData.Text.ongoing, start: -TestData.Time.tenMinutes, end: TestData.Time.thirtyMinutes)
        let inner = Fixtures.event(TestData.Text.contained, start: TestData.Time.origin, end: TestData.Time.tenMinutes)
        let overlap = Fixtures.event(TestData.Text.overlap, start: TestData.Time.twentyMinutes, end: TestData.Time.fortyMinutes)
        let adjacent = Fixtures.event(TestData.Text.adjacent, start: TestData.Time.fortyMinutes, end: TestData.Time.fiftyMinutes)
        let next = Fixtures.event(TestData.Text.next, start: TestData.Time.oneHour, end: TestData.Time.seventyMinutes)
        let intervals = ProposalInterval.available(events: [next, inner, adjacent, ongoing, overlap], now: Fixtures.now)
        #expect(intervals.count == TestData.Count.single)
        let interval = try #require(intervals.first)
        #expect(interval.from?.id == .event(adjacent.persistentModelID))
        #expect(interval.start == adjacent.end)
        #expect(interval.to.id == .event(next.persistentModelID))
    }

    // INT-005
    // 翌日の予定を含む順不同の入力から時系列の区間を生成し、最後の予定の後には区間を追加しないことを確認する。
    @Test func intervalsAreOrderedAndHaveNoTrailingGap() {
        let first = Fixtures.event(TestData.Text.first)
        let next = Fixtures.event(TestData.Text.nextDay, start: TestData.Time.oneDay, end: TestData.Time.nextDayEnd)
        let intervals = ProposalInterval.available(events: [next, first], now: Fixtures.now)
        #expect(intervals.map(\.to.title) == TestData.Schedule.orderedTitles)
        #expect(intervals.count == TestData.Count.pair)
        #expect(intervals.last?.from?.id == .event(first.persistentModelID))
        #expect(intervals.last?.start == first.end)
    }

    // GAP-001
    // 移動すると次の開始に間に合わない場合、移動・休憩を作成せず、所要分数を切り上げた遅刻の案内を返すことを確認する。
    @Test func lateArrivalReturnsWarningWithoutTravel() {
        let gap = ProposalGap.planned(from: Fixtures.proposal(end: TestData.Time.origin),
                                      to: Fixtures.proposal(start: TestData.Time.tenMinutes), duration: TestData.Time.lateTravel)
        #expect(gap.plan?.travel == nil)
        #expect(gap.plan?.rest?.start == nil && gap.plan?.rest?.end == nil)
        #expect(gap == .unavailable(.arrivalTooLate(requiredMinutes: 11)))
    }

    // GAP-002, GAP-003, GAP-004
    // 到着から開始までの余裕を境界値ごとに変え、10分未満なら余裕不足、10分以上なら準備時間確保の案内になることを確認する。
    // 準備10分を除いて5分以上残る場合だけ、到着から準備開始までの休憩を作成することを確認する。
    @Test(arguments: TestData.Schedule.arrivalMargins)
    func arrivalMarginBoundaries(margin: Double) throws {
        let gap = ProposalGap.planned(from: Fixtures.proposal(end: TestData.Time.origin),
                                      to: Fixtures.proposal(start: TestData.Time.twentyMinutes), duration: TestData.Time.twentyMinutes - margin)
        let travel = try #require(gap.plan?.travel)
        #expect(travel.departure == Fixtures.now)
        #expect(travel.arrival == Fixtures.now.addingTimeInterval(TestData.Time.twentyMinutes - margin))
        #expect(gap.plan?.notice == (margin < TestData.Time.tenMinutes ? .insufficientPreparation : .preparationReserved))
        if margin >= TestData.Time.minimumMarginForRest {
            #expect(gap.plan?.rest?.start == travel.arrival)
            #expect(gap.plan?.rest?.end == Fixtures.now.addingTimeInterval(TestData.Time.tenMinutes))
        } else {
            #expect(gap.plan?.rest?.start == nil && gap.plan?.rest?.end == nil)
        }
    }

    // GAP-005
    // 移動時間0・場所名なしの場合、出発と到着が同時になり、移動の場所名には予定タイトルを使うことを確認する。
    @Test func zeroTravelUsesEventTitlesWhenLocationsAreAbsent() throws {
        var from = Fixtures.proposal(TestData.Text.departure, end: TestData.Time.origin)
        var to = Fixtures.proposal(TestData.Text.arrival, start: TestData.Time.thirtyMinutes)
        from.location = nil
        to.location = nil
        let gap = ProposalGap.planned(from: from, to: to, duration: TestData.Time.origin)
        let travel = try #require(gap.plan?.travel)
        #expect(travel.originName == TestData.Text.departure)
        #expect(travel.destinationName == TestData.Text.arrival)
        #expect(travel.departure == travel.arrival)
        #expect(travel.duration == TestData.Time.origin)
    }
}
