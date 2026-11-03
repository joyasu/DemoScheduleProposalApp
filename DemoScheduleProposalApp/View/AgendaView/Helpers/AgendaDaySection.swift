//
//  AgendaDaySection.swift
//  DemoScheduleProposalApp
//

//
//  日付ごとの予定、現在時刻、空き区間などを一覧のセクションとして表示する。

import SwiftUI

struct AgendaDaySection: View {
    let day: AgendaDayContent
    let now: Date
    let isSelecting: Bool
    let edit: (ScheduleEvent) -> Void
    let toggleCompletion: (ScheduleEvent) -> Void

    var body: some View {
        Section {
            HStack {
                Text(day.date, format: .dateTime.month().day().weekday())
                if day.isToday {
                    Text("今日").foregroundStyle(.teal)
                }
            }
            .font(.headline)
            .textCase(nil)
            .id(day.date)
            .selectionDisabled(true)
            .agendaDayFrame(day.date)

            ForEach(isSelecting ? day.selectionRows : day.rows) { row in
                switch row {
                case .event(let event):
                    AgendaEventRow(event: event, now: now, isSelecting: isSelecting,
                                   edit: edit, toggleCompletion: toggleCompletion)
                        .agendaDayFrame(day.date)
                case .interval(let interval):
                    ProposalIntervalRow(interval: interval)
                        .agendaDayFrame(day.date)
                case .now:
                    NowCard(now: now)
                        .agendaDayFrame(day.date)
                        .tag(AgendaSelectionID.now)
                        .selectionDisabled(true)
                        .listRowSeparator(.hidden)
                case .empty:
                    Text("予定はありません")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 16)
                        .selectionDisabled(true)
                        .agendaDayFrame(day.date)
                }
            }
        }
    }
}
