//
//  AgendaWeekHeader.swift
//  DemoScheduleProposalApp
//

//
//  週の日付と選択状態を表示し、日付選択や週の切り替えを受け付ける。

import SwiftUI

struct AgendaWeekHeader: View {
    let selectedDate: Date
    let weekDate: Date
    let weekDates: [Date]
    @Environment(\.calendar) private var calendar
    let changeWeek: (Int) -> Void
    let now: Date
    let select: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weekDate, format: .dateTime.year().month(.wide))
                .font(.title2.bold())
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let today = calendar.isDate(date, inSameDayAs: now)
                    Button { select(date) } label: {
                        VStack(spacing: 6) {
                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.caption)
                            Text(date, format: .dateTime.day())
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(selected ? Color.teal : today ? Color.teal.opacity(0.15) : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(selected ? Color.white : Color.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .padding()
        .background(.background)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    changeWeek(value.translation.width > 0 ? -1 : 1)
                }
        )
        .accessibilityAction(named: "前の週") { changeWeek(-1) }
        .accessibilityAction(named: "次の週") { changeWeek(1) }
    }
}
