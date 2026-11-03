//
//  EventEditorTests.swift
//  DemoScheduleProposalApp
//
//
//  予定の下書き、入力検証、日時調整、保存・削除を検証するテスト。

import Foundation
import SwiftData
import Testing
@testable import DemoScheduleProposalApp

@MainActor
struct EventEditorTests {
    // EDT-001
    // 既存予定の値が下書きへコピーされ、下書きのタイトル・日時・場所名・メモを変えても保存前の元データは変わらないことを確認する。
    @Test func draftCopiesValuesWithoutEditingOriginal() {
        let event = Fixtures.event()
        event.location = Fixtures.location()
        var draft = EventDraft(event: event)
        #expect(draft.event === event)
        #expect(draft.title == event.title && draft.start == event.start && draft.end == event.end)
        #expect(draft.location == event.location && draft.memo == event.memo && draft.isAllDay == event.isAllDay)
        draft.title = TestData.Text.draft
        draft.start = Fixtures.now
        draft.location?.name = TestData.Text.changed
        draft.memo = TestData.Text.empty
        #expect(event.title == TestData.Text.title)
        #expect(event.start == Fixtures.now.addingTimeInterval(TestData.Time.tenMinutes))
        #expect(event.location?.name == TestData.Text.location)
        #expect(event.memo == TestData.Text.memo)
    }

    // EDT-002
    // 空文字・空白のみ・改行とタブのみのタイトルは保存不可となり、日時の警告は表示しないことを確認する。
    @Test(arguments: TestData.Editor.blankTitles)
    func blankTitleCannotSave(title: String) {
        var draft = EventDraft(event: Fixtures.event())
        draft.title = title
        let model = EventEditorViewModel(draft: draft)
        #expect(!model.isValid)
        #expect(!model.showsInvalidDates)
    }

    // EDT-003
    // 時間指定予定の終了が開始より前・同時・後の各ケースで、前の場合だけ無効となり日時の警告が表示されることを確認する。
    @Test(arguments: TestData.Editor.durationCases)
    func timedDateValidation(duration: Double) {
        var draft = EventDraft()
        draft.title = TestData.Text.title
        draft.start = Fixtures.now
        draft.end = Fixtures.now.addingTimeInterval(duration)
        let model = EventEditorViewModel(draft: draft)
        #expect(model.isValid == (duration >= TestData.Time.origin))
        #expect(model.showsInvalidDates == (duration < TestData.Time.origin))
    }

    // EDT-004
    // 終日予定の終了日を前日・同日・翌日へ変え、同日の時刻差は無視して前日だけ無効と判定することを確認する。
    @Test(arguments: TestData.Dates.dayOffsets)
    func allDayValidationIgnoresTimeOfDay(dayOffset: Int) throws {
        var draft = EventDraft()
        draft.title = TestData.Text.allDay
        draft.isAllDay = true
        draft.start = try Fixtures.date()
        let midnight = Calendar.current.startOfDay(for: draft.start)
        draft.end = try #require(Calendar.current.date(byAdding: .day, value: dayOffset, to: midnight))
        #expect(EventEditorViewModel(draft: draft).isValid == (dayOffset >= TestData.Dates.sameDayOffset))
    }

    // EDT-005
    // 開始または終了を変更して前後関係を逆転させ、編集した側の日時を保持したまま、元の所要時間に合わせて反対側が移動することを確認する。
    @Test(arguments: TestData.booleanCases)
    func crossingTimedEndpointPreservesDuration(editStart: Bool) {
        let model = EventEditorViewModel(draft: EventDraft(event: Fixtures.event(start: TestData.Time.origin, end: TestData.Time.oneHour)))
        let edited = Fixtures.now.addingTimeInterval(editStart ? TestData.Time.twoHours : -TestData.Time.twoHours)
        if editStart { model.start = edited } else { model.end = edited }
        #expect((editStart ? model.start : model.end) == edited)
        #expect(model.end.timeIntervalSince(model.start) == TestData.Time.oneHour)
    }

    // EDT-006
    // 終日予定の開始日または終了日を変更して逆転させ、編集した側を保持したまま元の日数差が保たれることを確認する。
    @Test(arguments: TestData.booleanCases)
    func crossingAllDayEndpointPreservesDayCount(editStart: Bool) throws {
        let event = Fixtures.event(allDay: true)
        event.start = try Fixtures.date(TestData.Dates.today)
        event.end = try Fixtures.date(TestData.Dates.allDayEnd)
        let model = EventEditorViewModel(draft: EventDraft(event: event))
        let edited = try Fixtures.date(editStart ? TestData.Dates.shiftedStart : TestData.Dates.shiftedEnd)
        if editStart { model.start = edited } else { model.end = edited }
        #expect((editStart ? model.start : model.end) == edited)
        #expect(Calendar.current.dateComponents([.day], from: model.start, to: model.end).day == TestData.Dates.allDayDuration)
    }

    // EDT-007
    // 開始と終了が逆転しない範囲でそれぞれ編集し、編集していない側の日時が変わらないことを確認する。
    @Test func nonCrossingEditsKeepOtherEndpoint() {
        let model = EventEditorViewModel(draft: EventDraft(event: Fixtures.event(start: TestData.Time.origin, end: TestData.Time.oneHour)))
        let end = model.end
        model.start = Fixtures.now.addingTimeInterval(TestData.Time.tenMinutes)
        #expect(model.end == end)
        let start = model.start
        model.end = Fixtures.now.addingTimeInterval(TestData.Time.fortyMinutes)
        #expect(model.start == start)
    }

    // EDT-008
    // 新規予定を保存し、タイトルの前後空白が除去され、日時・場所・メモが別の保存コンテキストからも読み取れることを確認する。
    @Test func savingNewDraftPersistsTrimmedFields() throws {
        let context = try Fixtures.context()
        var draft = EventDraft()
        draft.title = TestData.Text.paddedTitle
        draft.start = Fixtures.now
        draft.end = Fixtures.now.addingTimeInterval(TestData.Time.tenMinutes)
        draft.location = Fixtures.location()
        draft.memo = TestData.Text.savedMemo
        let model = EventEditorViewModel(draft: draft)
        #expect(model.save(in: context))
        let stored = try Fixtures.fetch(ModelContext(context.container))
        #expect(stored.count == TestData.Count.single)
        let event = try #require(stored.first)
        #expect(event.title == TestData.Text.newTitle)
        #expect(event.start == draft.start && event.end == draft.end)
        #expect(event.location == draft.location && event.memo == draft.memo)
        #expect(!context.hasChanges)
    }

    // EDT-009
    // 既存予定のタイトル・場所・メモを更新し、件数・ID・完了状態を保ったまま保存されることを確認する。
    @Test func savingExistingEventKeepsIdentityAndCompletion() throws {
        let context = try Fixtures.context()
        let event = Fixtures.event(completed: true)
        context.insert(event)
        try context.save()
        let id = event.persistentModelID
        let model = EventEditorViewModel(draft: EventDraft(event: event))
        model.draft.title = TestData.Text.updated
        model.draft.memo = TestData.Text.updatedMemo
        model.draft.location = Fixtures.location()
        #expect(model.save(in: context))
        let stored = try Fixtures.fetch(ModelContext(context.container))
        #expect(stored.count == TestData.Count.single)
        let updated = try #require(stored.first)
        #expect(updated.persistentModelID == id)
        #expect(updated.title == TestData.Text.updated && updated.isCompleted)
        #expect(updated.memo == TestData.Text.updatedMemo && updated.location == model.draft.location)
    }

    // EDT-010
    // 時刻を含む終日予定を保存し、開始・終了がそれぞれ当日の開始時刻へ正規化され、終日フラグも保存されることを確認する。
    @Test func allDaySaveNormalizesBothDates() throws {
        let context = try Fixtures.context()
        var draft = EventDraft()
        draft.title = TestData.Text.allDay
        draft.isAllDay = true
        draft.start = try Fixtures.date(TestData.Dates.saveStart)
        draft.end = try Fixtures.date(TestData.Dates.saveEnd)
        #expect(EventEditorViewModel(draft: draft).save(in: context))
        let stored = try #require(Fixtures.fetch(ModelContext(context.container)).first)
        #expect(stored.start == Calendar.current.startOfDay(for: draft.start))
        #expect(stored.end == Calendar.current.startOfDay(for: draft.end))
        #expect(stored.isAllDay)
    }

    // EDT-011
    // 新規・既存の両方で空白タイトルの保存を試し、保存が失敗して件数・元の値・未保存の変更状態に影響しないことを確認する。
    @Test(arguments: TestData.booleanCases)
    func invalidDraftDoesNotWrite(existing: Bool) throws {
        let context = try Fixtures.context()
        let event = Fixtures.event()
        if existing {
            context.insert(event)
            try context.save()
        }
        var draft = EventDraft(event: existing ? event : nil)
        draft.title = TestData.Text.whitespace
        let model = EventEditorViewModel(draft: draft)
        #expect(!model.save(in: context))
        #expect(try Fixtures.fetch(context).count == (existing ? TestData.Count.single : TestData.Count.none))
        #expect(event.title == TestData.Text.title)
        #expect(!context.hasChanges)
    }

    // EDT-012
    // 未保存の下書きの削除は失敗して既存予定に影響せず、保存済み予定の削除は成功して別コンテキストでも0件になることを確認する。
    @Test func deletingExistingAndUnsavedDrafts() throws {
        let context = try Fixtures.context()
        let event = Fixtures.event()
        context.insert(event)
        try context.save()
        #expect(!EventEditorViewModel(draft: EventDraft()).delete(in: context))
        #expect(try Fixtures.fetch(context).count == TestData.Count.single)
        #expect(EventEditorViewModel(draft: EventDraft(event: event)).delete(in: context))
        #expect(try Fixtures.fetch(ModelContext(context.container)).isEmpty)
    }

    // EDT-013
    // 追加・更新・削除の保存時にエラーを発生させ、変更がロールバックされて元の予定が残り、保存エラー表示が有効になることを確認する。
    @Test(arguments: TestData.Editor.persistenceOperations)
    func persistenceFailureRollsBack(operation: String) throws {
        let context = try Fixtures.context()
        let event = Fixtures.event()
        context.insert(event)
        try context.save()
        let model = EventEditorViewModel(draft: EventDraft(event: operation == TestData.Editor.insertOperation ? nil : event))
        model.draft.title = TestData.Text.changed
        var attempted = false
        let fail: (ModelContext) throws -> Void = { context in
            attempted = true
            #expect(context.hasChanges)
            throw TestFailure.injected
        }
        let success = operation == TestData.Editor.deleteOperation
            ? model.delete(in: context, saveChanges: fail)
            : model.save(in: context, saveChanges: fail)
        #expect(!success && attempted && model.showsSaveError)
        let stored = try Fixtures.fetch(context)
        #expect(stored.count == TestData.Count.single)
        #expect(stored.first?.title == TestData.Text.title)
        #expect(!context.hasChanges)
    }
}
