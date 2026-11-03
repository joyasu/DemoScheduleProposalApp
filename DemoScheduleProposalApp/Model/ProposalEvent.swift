//
//  ProposalEvent.swift
//  DemoScheduleProposalApp
//

//
//  提案処理で使用する予定の値を保持し、現在地を起点とする予定も表現する。

import Foundation
import SwiftData

struct ProposalEvent: Identifiable {
    let id: AgendaSelectionID
    let title: String
    let start: Date
    let end: Date
    var location: EventLocation?
    let memo: String

    init(_ event: ScheduleEvent) {
        id = .event(event.persistentModelID)
        title = event.title
        start = event.start
        end = event.end
        location = event.location
        memo = event.memo
    }

    init(now: Date, location: EventLocation) {
        id = .now
        title = "今"
        start = now
        end = now
        self.location = location
        memo = ""
    }
}
