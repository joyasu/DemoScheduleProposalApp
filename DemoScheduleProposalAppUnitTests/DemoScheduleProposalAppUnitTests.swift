import Foundation
import Testing
@testable import DemoScheduleProposalApp

@Suite(.timeLimit(.minutes(TestData.suiteTimeoutMinutes)))
@MainActor
struct ProposalResultTests {
    // RES-001
    // 場所未設定・座標不足・範囲外の座標は再設定が必要となり、有効な座標なら再設定不要となることを確認する。
    @Test func locationValidity() {
        let event = Fixtures.proposal()
        let model = ProposalResultViewModel(request: ProposalRequest(intervals: []))
        let invalid = Fixtures.invalidEventLocations
        for location in invalid {
            var candidate = event
            candidate.location = location
            #expect(model.needsLocation(candidate))
        }
        #expect(!model.needsLocation(event))
    }

    // RES-002
    // 場所を設定した予定IDだけに変更が反映され、元データと別の予定は変わらず、再試行番号が増えることを確認する。
    @Test func settingLocationOnlyUpdatesMatchingID() {
        let first = Fixtures.proposal(TestData.Text.first)
        let second = Fixtures.proposal(TestData.Text.other)
        let model = ProposalResultViewModel(request: ProposalRequest(intervals: []))
        let replacement = Fixtures.location(TestData.Text.replacementLocation)
        model.setLocation(replacement, for: first)
        #expect(model.attempt == TestData.Count.single)
        #expect(model.resolved(first).location == replacement)
        #expect(model.resolved(second).location == second.location)
        #expect(first.location?.name == TestData.Text.first)
    }

    // RES-003
    // 現在地を起点にする場合だけ位置情報を取得し、固定時刻と設定し直した目的地を使って提案を保存することを確認する。
    // 予定を起点にする場合は、その予定の日時を使い、現在地を取得しないことも確認する。
    @Test(arguments: TestData.booleanCases)
    func loadUsesLocationOnlyForCurrentOrigin(needsCurrentLocation: Bool) async throws {
        let first = Fixtures.proposal(TestData.Text.departure, end: TestData.Time.origin)
        let next = Fixtures.proposal(TestData.Text.next, start: TestData.Time.oneHour)
        let interval = Fixtures.interval(from: needsCurrentLocation ? nil : first, to: next)
        var locationCalls = 0
        var received: [(ProposalEvent, ProposalEvent)] = []
        let current = Fixtures.location(TestData.Text.currentLocationFixture)
        let fixedNow = Fixtures.now.addingTimeInterval(TestData.Time.oneMinute)
        let model = ProposalResultViewModel(
            request: ProposalRequest(intervals: [interval]),
            currentLocation: { locationCalls += 1; return current },
            makeGap: { from, to in
                received.append((from, to))
                return .unavailable(.missingLocation)
            },
            now: { fixedNow }
        )
        let destination = Fixtures.location(TestData.Text.replacementDestination)
        model.setLocation(destination, for: next)
        await model.load()
        #expect(locationCalls == (needsCurrentLocation ? TestData.Count.single : TestData.Count.none))
        #expect(received.count == TestData.Count.single)
        let call = try #require(received.first)
        #expect(call.1.location == destination)
        #expect(call.0.start == (needsCurrentLocation ? fixedNow : first.start))
        #expect(model.gaps[interval.id] == .unavailable(.missingLocation))
        #expect(!model.isLoading && model.locationError == nil)
        if needsCurrentLocation {
            #expect(model.currentOrigin?.location == current)
        } else {
            #expect(model.currentOrigin == nil)
        }
    }

    // RES-004
    // 現在地取得を失敗させ、エラーを保持しつつ、現在地を必要としない予定間の区間は引き続き提案されることを確認する。
    @Test func locationFailureStillLoadsScheduledIntervals() async {
        let first = Fixtures.proposal()
        let next = Fixtures.proposal(TestData.Text.next, start: TestData.Time.oneHour)
        let currentInterval = Fixtures.interval(to: first)
        let scheduledInterval = Fixtures.interval(from: first, to: next)
        var calls = 0
        let model = ProposalResultViewModel(
            request: ProposalRequest(intervals: [currentInterval, scheduledInterval]),
            currentLocation: { throw CurrentLocationError.denied },
            makeGap: { _, _ in calls += 1; return .unavailable(.routeUnavailable) }
        )
        await model.load()
        #expect(model.locationError == CurrentLocationError.denied.localizedDescription)
        #expect(model.currentOrigin == nil && !model.isLoading)
        #expect(model.gaps[currentInterval.id] == nil)
        #expect(model.gaps[scheduledInterval.id] == .unavailable(.routeUnavailable))
        #expect(calls == TestData.Count.single)
    }

    // RES-005
    // 再読み込みで以前の提案が消え、キャンセル後に遅れて成功応答が届いても結果を保存せず、読み込み状態が終了することを確認する。
    @Test func reloadClearsResultsAndCancelledResponseIsDiscarded() async {
        let interval = Fixtures.interval(from: Fixtures.proposal(), to: Fixtures.proposal(TestData.Text.next, start: TestData.Time.oneHour))
        let gate = TestGate<ProposalGap>()
        var calls = 0
        let model = ProposalResultViewModel(
            request: ProposalRequest(intervals: [interval]),
            makeGap: { _, _ in
                calls += 1
                if calls == TestData.Count.single { return .unavailable(.overlappingEvents) }
                return try await gate.wait()
            }
        )
        await model.load()
        #expect(model.gaps.count == TestData.Count.single)
        let reload = Task { await model.load() }
        await gate.started.wait()
        #expect(model.isLoading && model.gaps.isEmpty)
        reload.cancel()
        gate.resolve(.success(.unavailable(.invalidTravelTime)))
        await reload.value
        #expect(model.gaps.isEmpty && !model.isLoading)
    }

    // RES-005
    // 現在地取得中にキャンセルし、その後届いた位置情報が起点やエラーとして反映されず、区間の提案も実行されないことを確認する。
    @Test func cancelledLocationDoesNotWriteOriginOrError() async {
        let gate = TestGate<EventLocation>()
        let interval = Fixtures.interval(to: Fixtures.proposal(start: TestData.Time.oneHour))
        var gapCalls = 0
        let model = ProposalResultViewModel(
            request: ProposalRequest(intervals: [interval]),
            currentLocation: { try await gate.wait() },
            makeGap: { _, _ in gapCalls += 1; return .unavailable(.unexpectedFailure) }
        )
        let load = Task { await model.load() }
        await gate.started.wait()
        load.cancel()
        gate.resolve(.success(Fixtures.location()))
        await load.value
        #expect(model.currentOrigin == nil && model.locationError == nil)
        #expect(gapCalls == TestData.Count.none && !model.isLoading)
    }
}
