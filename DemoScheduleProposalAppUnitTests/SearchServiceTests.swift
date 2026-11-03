//
//  SearchServiceTests.swift
//  DemoScheduleProposalApp
//

//
//  経路検索による提案生成と場所検索の正常系・異常系を検証するテスト。

import Foundation
import MapKit
import Testing
@testable import DemoScheduleProposalApp

@Suite(.timeLimit(.minutes(TestData.suiteTimeoutMinutes)))
@MainActor
struct SearchServiceTests {
    // SVC-001
    // 時間が重複する予定や場所未設定・不正座標の予定では経路検索を呼び出さず、理由を示す案内を返すことを確認する。
    @Test func invalidGapsNeverRequestDirections() async throws {
        var calls = 0
        let service = ProposalService(calculateETA: { _ in calls += 1; return TestData.Time.oneMinute })
        let from = Fixtures.proposal(end: TestData.Time.twentyMinutes)
        let overlapping = Fixtures.proposal(start: TestData.Time.tenMinutes)
        let overlap = try await service.makeGap(from: from, to: overlapping)
        #expect(overlap == .unavailable(.overlappingEvents))
        let invalidLocations = Fixtures.invalidRouteLocations
        for location in invalidLocations {
            var destination = Fixtures.proposal(start: TestData.Time.oneHour)
            destination.location = location
            let gap = try await service.makeGap(from: from, to: destination)
            #expect(gap == .unavailable(.missingLocation))
        }
        #expect(calls == TestData.Count.none)
    }

    // SVC-002
    // 車移動・出発日時・出発地・目的地を経路検索へ渡し、返された移動時間から到着と休憩の日時を計算することを確認する。
    @Test func validETAUsesCarDepartureAndEndpoints() async throws {
        let from = Fixtures.proposal(TestData.Text.departure, end: TestData.Time.origin)
        let to = Fixtures.proposal(TestData.Text.arrival, start: TestData.Time.oneHour)
        var calls = 0
        let service = ProposalService { request in
            calls += 1
            #expect(request.transportType == .automobile)
            #expect(request.departureDate == from.end)
            #expect(request.source?.name == TestData.Text.departure)
            #expect(request.destination?.name == TestData.Text.arrival)
            return TestData.Time.tenMinutes
        }
        let gap = try await service.makeGap(from: from, to: to)
        #expect(calls == TestData.Count.single)
        #expect(gap.plan?.travel.arrival == Fixtures.now.addingTimeInterval(TestData.Time.tenMinutes))
        #expect(gap.plan?.rest?.start == gap.plan?.travel.arrival)
        #expect(gap.plan?.rest?.end == to.start.addingTimeInterval(-TestData.Time.tenMinutes))
    }

    // SVC-002
    // 経路検索が負数・正負の無限大・NaNを返す各ケースで、移動や休憩を作成せず無効な移動時間の案内を返すことを確認する。
    @Test(arguments: TestData.Search.invalidDurations)
    func invalidETAIsRejected(duration: Double) async throws {
        let service = ProposalService { _ in duration }
        let gap = try await service.makeGap(from: Fixtures.proposal(end: TestData.Time.origin), to: Fixtures.proposal(start: TestData.Time.oneHour))
        #expect(gap.plan?.travel == nil && gap.plan?.rest?.start == nil)
        #expect(gap == .unavailable(.invalidTravelTime))
    }

    // SVC-002
    // 経路検索で通信エラーを再現し、移動を作成せず再試行を促す案内を返すことを確認する。
    @Test func networkFailureReturnsRetryMessage() async throws {
        let service = ProposalService { _ in throw TestFailure.injected }
        let gap = try await service.makeGap(from: Fixtures.proposal(end: TestData.Time.origin), to: Fixtures.proposal(start: TestData.Time.oneHour))
        #expect(gap.plan?.travel == nil)
        #expect(gap == .unavailable(.routeUnavailable))
    }

    // SVC-003
    // 経路検索中にキャンセルし、その後の応答が成功・失敗のどちらでも通常の提案結果ではなくCancellationErrorになることを確認する。
    @Test(arguments: TestData.booleanCases)
    func cancelledDirectionsThrowCancellation(lateSuccess: Bool) async {
        let gate = TestGate<TimeInterval>()
        let service = ProposalService { _ in try await gate.wait() }
        let task = Task {
            try await service.makeGap(from: Fixtures.proposal(end: TestData.Time.origin), to: Fixtures.proposal(start: TestData.Time.oneHour))
        }
        await gate.started.wait()
        task.cancel()
        gate.resolve(lateSuccess ? .success(TestData.Time.oneMinute) : .failure(TestFailure.injected))
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    // LOC-001
    // 検索文字列の前後の空白・改行が除去され、空検索では通信せず以前の結果・案内・検索中状態が消えることを確認する。
    @Test func emptySearchClearsStateWithoutCallingService() async {
        var calls = 0
        let model = LocationPickerViewModel(searchLocations: { _ in calls += 1; return [] }, debounce: {})
        model.query = TestData.Text.paddedQuery
        #expect(model.searchText == TestData.Text.location)
        model.query = TestData.Text.blankQuery
        model.results = [Fixtures.location()]
        model.message = TestData.Text.previousMessage
        model.isSearching = true
        await model.search(model.searchText)
        #expect(model.results.isEmpty && model.message.isEmpty && !model.isSearching)
        #expect(calls == TestData.Count.none)
    }

    // LOC-002
    // 場所検索の成功・0件・エラーをそれぞれ再現し、結果または対応する案内が表示され、検索中状態が終了することを確認する。
    @Test(arguments: TestData.Search.outcomes)
    func searchOutcomes(outcome: String) async {
        let location = Fixtures.location()
        let model = LocationPickerViewModel(
            searchLocations: { query in
                #expect(query == TestData.Text.location)
                if outcome == TestData.Search.errorOutcome { throw TestFailure.injected }
                return outcome == TestData.Search.emptyOutcome ? [] : [location]
            },
            debounce: {}
        )
        await model.search(TestData.Text.location)
        #expect(!model.isSearching)
        if outcome == TestData.Search.successOutcome {
            #expect(model.results == [location] && model.message.isEmpty)
        } else {
            #expect(model.results.isEmpty)
            #expect(model.message.contains(outcome == TestData.Search.emptyOutcome ? TestData.Message.noSearchResults : TestData.Message.searchFailed))
        }
    }

    // LOC-002
    // 古い検索をキャンセルして新しい検索を完了した後、古い応答を返しても最新の結果が上書きされないことを確認する。
    @Test func cancelledOldSearchCannotOverwriteNewResults() async {
        let gate = TestGate<[EventLocation]>()
        let latest = Fixtures.location(TestData.Text.latest)
        let model = LocationPickerViewModel(
            searchLocations: { query in
                query == TestData.Text.oldQuery ? try await gate.wait() : [latest]
            },
            debounce: {}
        )
        let old = Task { await model.search(TestData.Text.oldQuery) }
        await gate.started.wait()
        old.cancel()
        await model.search(TestData.Text.newQuery)
        gate.resolve(.success([Fixtures.location(TestData.Text.oldResult)]))
        await old.value
        #expect(model.results == [latest])
        #expect(model.message.isEmpty && !model.isSearching)
    }

    // LOC-002
    // 入力待機中に検索をキャンセルして空検索へ切り替え、待機終了後も通信せず結果・案内・検索中状態が空に保たれることを確認する。
    @Test func cancellationDuringDebounceSkipsNetwork() async {
        let gate = TestGate<Void>()
        var calls = 0
        let model = LocationPickerViewModel(
            searchLocations: { _ in calls += 1; return [] },
            debounce: { try await gate.wait() }
        )
        let task = Task { await model.search(TestData.Text.location) }
        await gate.started.wait()
        task.cancel()
        await model.search(TestData.Text.empty)
        gate.resolve(.success(()))
        await task.value
        #expect(calls == TestData.Count.none)
        #expect(model.results.isEmpty && model.message.isEmpty && !model.isSearching)
    }
}
