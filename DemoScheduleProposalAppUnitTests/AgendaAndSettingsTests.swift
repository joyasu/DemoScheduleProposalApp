//
//  AgendaAndSettingsTests.swift
//  DemoScheduleProposalApp
//

//
//  提案対象の区間選択、予定の完了操作、設定からのデータ削除を検証するテスト。

import Foundation
import SwiftData
import Testing
@testable import DemoScheduleProposalApp

@MainActor
struct AgendaAndSettingsTests {
    // SEL-001
    // 区間選択の開始・キャンセルを行い、選択内容が空になって選択モードが切り替わることを確認する。
    @Test func selectionLifecycleClearsSelection() throws {
        let model = AgendaViewModel()
        let interval = try #require(ProposalInterval.available(events: [Fixtures.event()], now: Fixtures.now).first)
        model.selection = [interval.id]
        model.beginSelection()
        #expect(model.isSelecting && model.selection.isEmpty)
        model.selection = [interval.id]
        model.cancelSelection()
        #expect(!model.isSelecting && model.selection.isEmpty)
    }

    // SEL-002
    // 予定の完了・時間経過・開始日時の変更をそれぞれ再現し、無効になった区間が有効な選択から除外されることを確認する。
    @Test(arguments: TestData.Agenda.invalidSelectionReasons)
    func invalidSelectionsAreExcluded(reason: String) throws {
        let event = Fixtures.event()
        let model = AgendaViewModel()
        model.update(events: [event], now: Fixtures.now)
        let interval = try #require(model.intervals.first)
        model.selection = [interval.id]
        var now = Fixtures.now
        if reason == TestData.Agenda.completedReason { event.isCompleted = true }
        if reason == TestData.Agenda.elapsedReason { now = event.end }
        if reason == TestData.Agenda.changedReason { event.start = now.addingTimeInterval(-TestData.Time.oneMinute) }
        model.update(events: [event], now: now)
        #expect(model.validSelection.isEmpty)
    }

    // SEL-003
    // 過去の固定時刻を渡して選択区間だけがリクエストに含まれることを確認する。
    // 未選択または期限切れの区間しかない場合にはリクエストを作成しないことも確認する。
    @Test func executionUsesSuppliedTimeAndSelectedIntervals() throws {
        // Deliberately in the past relative to the real clock, catching Date.now regressions.
        let now = Date(timeIntervalSince1970: TestData.Time.historicalEpoch)
        let events = TestData.Agenda.eventIndices.map { index in
            let event = Fixtures.event(String(index))
            event.start = now.addingTimeInterval(Double(index) * TestData.Time.twentyMinutes + TestData.Time.tenMinutes)
            event.end = event.start.addingTimeInterval(TestData.Time.fiveMinutes)
            return event
        }
        let model = AgendaViewModel()
        model.update(events: events, now: now)
        model.execute()
        #expect(model.request == nil)
        let intervals = model.intervals
        try #require(intervals.count == TestData.Count.triple)
        model.selection = [intervals[0].id, intervals[2].id]
        model.execute()
        #expect(model.request?.intervals.map(\.id) == [intervals[0].id, intervals[2].id])
        let invalidModel = AgendaViewModel()
        invalidModel.selection = model.selection
        invalidModel.update(events: events, now: now.addingTimeInterval(TestData.Time.oneDay))
        invalidModel.execute()
        #expect(invalidModel.request == nil)
    }

    // SEL-004
    // 予定を完了にすると区間選択が解除され、完了・未完了への変更が別の保存コンテキストからも読み取れることを確認する。
    @Test func completingPersistsAndClearsSelection() throws {
        let context = try Fixtures.context()
        let event = Fixtures.event()
        context.insert(event)
        try context.save()
        let model = AgendaViewModel()
        let interval = try #require(ProposalInterval.available(events: [event], now: Fixtures.now).first)
        model.selection = [interval.id]
        model.toggleCompletion(event, in: context)
        #expect(event.isCompleted && model.selection.isEmpty)
        #expect(try Fixtures.fetch(ModelContext(context.container)).first?.isCompleted == true)
        model.toggleCompletion(event, in: context)
        #expect(!event.isCompleted)
        #expect(try Fixtures.fetch(ModelContext(context.container)).first?.isCompleted == false)
    }

    // SEL-005
    // 完了状態の保存でエラーを発生させ、元の状態と選択内容が維持されてエラー表示が有効になることを確認する。
    @Test func completionFailureRestoresStateAndSelection() throws {
        let context = try Fixtures.context()
        let event = Fixtures.event()
        context.insert(event)
        try context.save()
        let model = AgendaViewModel()
        let interval = try #require(ProposalInterval.available(events: [event], now: Fixtures.now).first)
        model.selection = [interval.id]
        model.toggleCompletion(event, in: context, saveChanges: { _ in throw TestFailure.injected })
        #expect(!event.isCompleted && model.showsCompletionError)
        #expect(model.selection == [interval.id])
        #expect(!context.hasChanges)
    }

    #if DEBUG
    // SET-001
    // 予定が0件・複数件の両方で全件削除が成功し、別の保存コンテキストから読み直しても0件になることを確認する。
    @Test(arguments: TestData.Agenda.deletionCounts)
    func deleteAllDataPersistsEmptyStore(count: Int) throws {
        let context = try Fixtures.context()
        for index in 0..<count { context.insert(Fixtures.event(String(index))) }
        try context.save()
        let model = SettingsViewModel()
        #expect(model.deleteAllData(in: context))
        #expect(try Fixtures.fetch(ModelContext(context.container)).isEmpty)
        #expect(!model.showsDeletionError)
    }

    // SET-002
    // 取得時・保存時のエラーをそれぞれ発生させ、全件削除が失敗して元の予定が残り、エラー表示が有効になることを確認する。
    @Test(arguments: TestData.booleanCases)
    func deleteAllFailureRestoresStore(failFetch: Bool) throws {
        let context = try Fixtures.context()
        context.insert(Fixtures.event())
        try context.save()
        let model = SettingsViewModel()
        let success: Bool
        if failFetch {
            success = model.deleteAllData(in: context, fetchEvents: { _ in throw TestFailure.injected })
        } else {
            success = model.deleteAllData(in: context, saveChanges: { _ in throw TestFailure.injected })
        }
        #expect(!success && model.showsDeletionError)
        #expect(try Fixtures.fetch(context).count == TestData.Count.single)
        #expect(!context.hasChanges)
    }
    #endif
}
