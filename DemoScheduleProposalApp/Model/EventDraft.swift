//
//  EventDraft.swift
//  DemoScheduleProposalApp
//

//
//  新規作成・編集中の予定の入力値を、保存前の下書きとして保持する。

import Foundation

struct EventDraft: Identifiable {
    let id = UUID()
    var event: ScheduleEvent?
    var title = ""
    var start = Date.now
    var end = Date.now.addingTimeInterval(3600)
    var isAllDay = false
    var location: EventLocation?
    var memo = ""

    init(event: ScheduleEvent? = nil, now: Date = .now) {
        self.event = event
        start = now
        end = now.addingTimeInterval(3600)
        if let event {
            title = event.title
            start = event.start
            end = event.end
            isAllDay = event.isAllDay
            location = event.location
            memo = event.memo
        }
    }
}
