//
//  ScheduleEvent.swift
//  DemoScheduleProposalApp
//

//
//  予定の日時、場所、完了状態などを保存し、指定時刻に進行中かどうかを判定する。

import Foundation
import SwiftData

@Model
final class ScheduleEvent {
    var title: String
    var start: Date
    var end: Date
    var isAllDay: Bool
    var isCompleted: Bool = false
    var location: EventLocation?
    var memo: String

    func isOngoing(at date: Date) -> Bool {
        !isCompleted && !isAllDay && start <= date && date < end
    }

    init(title: String, start: Date, end: Date, isAllDay: Bool, memo: String) {
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.memo = memo
    }
}
