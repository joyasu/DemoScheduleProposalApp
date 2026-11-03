//
//  AgendaDayContent.swift
//  DemoScheduleProposalApp
//

//
//  日別の予定一覧に表示する予定、空き区間、現在時刻などの行データを構成する。

import Foundation
import SwiftData

/// Prepared list rows keep grouping and interval lookup outside SwiftUI's body evaluation.
struct AgendaDayContent: Identifiable {
    enum Row: Identifiable {
        enum ID: Hashable {
            case event(AgendaSelectionID)
            case interval(ProposalInterval.ID)
            case now
            case empty
        }

        case event(ScheduleEvent)
        case interval(ProposalInterval)
        case now
        case empty

        var id: ID {
            switch self {
            case .event(let event): .event(.event(event.persistentModelID))
            case .interval(let interval): .interval(interval.id)
            case .now: .now
            case .empty: .empty
            }
        }
    }

    let date: Date
    let isToday: Bool
    let rows: [Row]
    let selectionRows: [Row]
    var id: Date { date }

    init(day: ScheduleDay, now: Date, calendar: Calendar,
         intervalsByDestination: [AgendaSelectionID: ProposalInterval]) {
        date = day.date
        isToday = calendar.isDate(day.date, inSameDayAs: now)
        var rows: [Row] = day.events.isEmpty ? [.empty] : []
        let preceding = isToday ? day.events.filter { $0.isAllDay || $0.start <= now } : day.events
        let following = isToday ? day.events.filter { !$0.isAllDay && $0.start > now } : []
        rows.append(contentsOf: preceding.map(Row.event))
        if isToday && !day.events.contains(where: { $0.isOngoing(at: now) }) {
            rows.append(.now)
        }
        rows.append(contentsOf: following.map(Row.event))
        self.rows = rows
        selectionRows = rows.flatMap { row -> [Row] in
            if case .event(let event) = row,
               let interval = intervalsByDestination[.event(event.persistentModelID)] {
                return [.interval(interval), row]
            }
            return [row]
        }
    }
}
