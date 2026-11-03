//
//  DemoScheduleData.swift
//  DemoScheduleProposalApp
//

//
//  予定一覧や提案機能の動作確認に使うデモ予定を生成し、空の保存先へ登録する。

import Foundation
import SwiftData

@MainActor
enum DemoScheduleData {
    // Demo coordinates around central Tokyo; these are not venue entrances.
    private static let tokyo = EventLocation(
        name: "東京駅周辺", latitude: 35.6812, longitude: 139.7671
    )
    private static let ginza = EventLocation(
        name: "銀座周辺", latitude: 35.6717, longitude: 139.7650
    )
    private static let ueno = EventLocation(
        name: "上野駅周辺", latitude: 35.7138, longitude: 139.7773
    )

    // Create fresh model instances for each container or preview.
    // Relative times may cross midnight when the demo starts late at night.
    static func events(now: Date = .now, calendar: Calendar = .current) -> [ScheduleEvent] {
        func event(_ title: String, from start: Double, to end: Double,
                   location: EventLocation? = nil, completed: Bool = false,
                   memo: String) -> ScheduleEvent {
            let event = ScheduleEvent(
                title: title,
                start: now.addingTimeInterval(start * 60),
                end: now.addingTimeInterval(end * 60),
                isAllDay: false,
                memo: memo
            )
            event.location = location
            event.isCompleted = completed
            return event
        }

        let today = calendar.startOfDay(for: now)
        let allDay = ScheduleEvent(
            title: "資料提出日", start: today, end: today, isAllDay: true,
            memo: "終日予定の表示確認"
        )
        var events = [
            allDay,
            event("完了した打ち合わせ", from: -90, to: -60, location: tokyo,
                  completed: true, memo: "完了表示と未完了への切り替えを確認"),
            event("作業中", from: -15, to: 30, location: tokyo,
                  memo: "この予定に「今」を表示"),
            event("完了済みの用事", from: 45, to: 60, location: ginza,
                  completed: true, memo: "空き区間の計算から除外される予定"),
            event("打ち合わせ", from: 120, to: 150, location: ginza,
                  memo: "作業終了から90分の空き。車移動・休憩の提案を確認"),
            event("続けて資料確認", from: 150, to: 180, location: ginza,
                  memo: "直前の予定と連続しているため区間を表示しない"),
            event("並行する電話", from: 160, to: 170, location: ginza,
                  memo: "重複予定。空き時間は資料確認の終了後から"),
            event("訪問", from: 270, to: 300, location: ueno,
                  memo: "重複予定の後の空き区間を確認"),
            event("場所未設定の予定", from: 360, to: 390,
                  memo: "場所がない場合の提案メッセージを確認")
        ]
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow),
           let end = calendar.date(byAdding: .hour, value: 1, to: start) {
            let event = ScheduleEvent(
                title: "翌日の打ち合わせ", start: start, end: end, isAllDay: false,
                memo: "翌日のセクション表示を確認"
            )
            event.location = tokyo
            events.append(event)
        }
        return events.sorted { $0.start < $1.start }
    }

    // Called only during debug startup. UI tests can pass -skipDemoData.
    static func seedIfEmpty(in container: ModelContainer, now: Date = .now) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var descriptor = FetchDescriptor<ScheduleEvent>()
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }
        do {
            for event in events(now: now) {
                context.insert(event)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func makeContainer(now: Date = .now) throws -> ModelContainer {
        let container = try ModelContainer(
            for: ScheduleEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for event in events(now: now) {
            container.mainContext.insert(event)
        }
        try container.mainContext.save()
        return container
    }
}
