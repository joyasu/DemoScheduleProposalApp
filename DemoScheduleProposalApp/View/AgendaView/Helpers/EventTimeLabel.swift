//
//  EventTimeLabel.swift
//  DemoScheduleProposalApp
//

//
//  予定の日時を、終日や日付をまたぐ場合に応じた形式で表示する。

import SwiftUI

struct EventTimeLabel: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone
    let start: Date
    let end: Date
    let isAllDay: Bool

    var body: some View {
        if calendar.isDate(start, inSameDayAs: end) {
            if isAllDay {
                Text("終日")
            } else {
                Text("\(start.formatted(style(date: .omitted, time: .shortened))) 〜 \(end.formatted(style(date: .omitted, time: .shortened)))")
            }
        } else if isAllDay {
            Text("\(start.formatted(style(date: .abbreviated, time: .omitted))) 〜 \(end.formatted(style(date: .abbreviated, time: .omitted)))・終日")
        } else {
            Text("\(start.formatted(style(date: .abbreviated, time: .shortened))) 〜 \(end.formatted(style(date: .abbreviated, time: .shortened)))")
        }
    }

    private func style(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: time, locale: locale, calendar: calendar, timeZone: timeZone)
    }
}
