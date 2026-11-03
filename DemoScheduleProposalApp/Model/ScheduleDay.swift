//
//  ScheduleDay.swift
//  DemoScheduleProposalApp
//

//
//  予定を日付ごとにまとめ、終日予定や進行中の予定の表示日を調整する。

import Foundation

struct ScheduleDay: Identifiable {
    let date: Date
    let events: [ScheduleEvent]
    var id: Date { date }

    static func upcoming(
        _ events: [ScheduleEvent], now: Date, calendar: Calendar = .current
    ) -> [ScheduleDay] {
        let today = calendar.startOfDay(for: now)
        var groups: [Date: [ScheduleEvent]] = [:]
        for event in events {
            if event.isAllDay {
                // All-day end dates are inclusive, including across daylight-saving changes.
                var day = calendar.startOfDay(for: event.start)
                let lastDay = max(day, calendar.startOfDay(for: event.end))
                while day <= lastDay {
                    groups[day, default: []].append(event)
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day),
                          nextDay > day else { break }
                    day = nextDay
                }
            } else {
                // Keep ongoing timed events under today, retaining past dates for navigation.
                let day = event.isOngoing(at: now) ? today : calendar.startOfDay(for: event.start)
                groups[day, default: []].append(event)
            }
        }
        return groups.keys.sorted().map { day in
            ScheduleDay(date: day, events: (groups[day] ?? []).sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay }
                return $0.start < $1.start
            })
        }
    }
}
