//
//  AgendaListView.swift
//  DemoScheduleProposalApp
//

//
//  週カレンダーと日別の予定一覧を表示し、日付選択とスクロールを連動させる。

import SwiftUI

struct AgendaListView: View {
    let days: [ScheduleDay]
    let daysByDate: [Date: AgendaDayContent]
    @Environment(\.calendar) private var calendar
    let now: Date
    let isSelecting: Bool
    @Binding var selection: Set<ProposalInterval.ID>
    let edit: (ScheduleEvent) -> Void
    let toggleCompletion: (ScheduleEvent) -> Void
    let add: () -> Void

    @State private var calendarModel = AgendaCalendarViewModel()
    @State private var pendingDate: Date?
    @State private var didScrollInitially = false

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                AgendaWeekHeader(selectedDate: calendarModel.selectedDate,
                                 weekDate: calendarModel.weekDate, weekDates: calendarModel.weekDates,
                                 changeWeek: { calendarModel.changeWeek(by: $0) }, now: now) { date in
                    calendarModel.selectedDate = date
                    pendingDate = date
                    proxy.scrollTo(date, anchor: .top)
                }
                GeometryReader { viewport in
                    List(selection: $selection) {
                        if isSelecting {
                            Text("空き時間の区間を選択してください。")
                                .foregroundStyle(.secondary)
                                .selectionDisabled(true)
                        }
                        ForEach(calendarModel.displayDates, id: \.self) { date in
                            let day = daysByDate[date] ?? AgendaDayContent(
                                day: ScheduleDay(date: date, events: []), now: now,
                                calendar: calendar, intervalsByDestination: [:])
                            AgendaDaySection(day: day, now: now, isSelecting: isSelecting,
                                             edit: edit, toggleCompletion: toggleCompletion)
                        }
                        Color.clear
                            .frame(height: viewport.size.height)
                            .listRowSeparator(.hidden)
                            .selectionDisabled(true)
                    }
                    .listStyle(.inset)
                    .coordinateSpace(name: "agendaList")
                    .onPreferenceChange(AgendaDayFrames.self) { frames in
                        if let target = pendingDate {
                            if let frame = frames[target], abs(frame.minY) < 40 {
                                pendingDate = nil
                            }
                            return
                        }
                        if let date = frames.filter({ $0.value.maxY > 1 && $0.value.minY < viewport.size.height })
                            .min(by: { $0.value.minY < $1.value.minY })?.key {
                            calendarModel.selectedDate = date
                        }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 3).onChanged { _ in
                        pendingDate = nil
                    })
                    .onChange(of: calendarModel.selectedDate) { _, date in
                        calendarModel.weekDate = date
                    }
                    .onChange(of: calendarModel.displayDates) { _, dates in
                        let today = calendar.startOfDay(for: now)
                        guard !didScrollInitially, dates.contains(today) else { return }
                        didScrollInitially = true
                        calendarModel.selectedDate = today
                        pendingDate = today
                        proxy.scrollTo(today, anchor: .top)
                    }
                    #if os(iOS)
                    .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
                    #endif
                }
            }
            .onChange(of: days.map(\.date), initial: true) { _, dates in
                calendarModel.update(scheduledDates: dates, now: now, calendar: calendar)
            }
            .onChange(of: calendar.startOfDay(for: now)) { _, _ in
                calendarModel.update(scheduledDates: days.map(\.date), now: now, calendar: calendar)
            }
            .onChange(of: calendar) { _, _ in
                pendingDate = nil
                didScrollInitially = false
                calendarModel.update(scheduledDates: days.map(\.date), now: now, calendar: calendar)
            }
        }
    }
}
