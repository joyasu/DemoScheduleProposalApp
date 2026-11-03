//
//  ProposalInterval.swift
//  DemoScheduleProposalApp
//

//
//  予定の重複や完了状態を考慮し、移動・休憩を提案できる空き区間を抽出する。

import Foundation

struct ProposalInterval: Identifiable {
    struct ID: Hashable {
        let from: AgendaSelectionID
        let to: AgendaSelectionID
    }
    let from: ProposalEvent?
    let to: ProposalEvent
    let start: Date
    var id: ID { ID(from: from?.id ?? .now, to: to.id) }

    static func available(events: [ScheduleEvent], now: Date) -> [ProposalInterval] {
        let sorted = events.filter { !$0.isCompleted && !$0.isAllDay && $0.end > now }
            .sorted { $0.start < $1.start }
        var intervals: [ProposalInterval] = []
        var end = now
        var origin: ProposalEvent?
        for event in sorted {
            let next = ProposalEvent(event)
            if next.start > end {
                intervals.append(ProposalInterval(from: origin, to: next, start: end))
            }
            // Overlapping events occupy time until the latest ending event.
            if next.end > end {
                end = next.end
                origin = next
            }
        }
        return intervals
    }
}
