//
//  AgendaCalendarViewModel.swift
//  DemoScheduleProposalApp
//

//
//  週の日付、選択日、閲覧履歴を管理し、一覧に表示する日付を構成する。

import Foundation
import Observation

@MainActor
@Observable
final class AgendaCalendarViewModel {
    var selectedDate: Date
    var weekDate: Date {
        didSet {
            if weekDate != oldValue {
                weekDates = Self.week(containing: weekDate, calendar: calendar)
            }
        }
    }
    private(set) var weekDates: [Date]
    private(set) var displayDates: [Date] = []
    private(set) var calendar: Calendar
    private var scheduledDates: [Date] = []
    private var today: Date
    private var browsedWeeks: [Date] = []
    // Keep recent navigation targets without retaining every visited empty week forever.
    static let maximumBrowsedWeeks = 12

    init(now: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        self.today = today
        selectedDate = today
        weekDate = today
        weekDates = Self.week(containing: today, calendar: calendar)
    }

    func update(scheduledDates: [Date], now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let calendarChanged = self.calendar != calendar
        guard self.scheduledDates != scheduledDates || self.today != today ||
                calendarChanged || displayDates.isEmpty else { return }
        if displayDates.isEmpty {
            selectedDate = today
            weekDate = today
        }
        self.scheduledDates = scheduledDates
        self.today = today
        if calendarChanged {
            self.calendar = calendar
            browsedWeeks = []
            selectedDate = calendar.startOfDay(for: selectedDate)
            weekDate = calendar.startOfDay(for: weekDate)
            weekDates = Self.week(containing: weekDate, calendar: calendar)
        }
        rebuildDisplayDates()
    }

    func changeWeek(by offset: Int) {
        guard let date = calendar.date(byAdding: .day, value: offset * 7, to: weekDate),
              let monday = Self.week(containing: date, calendar: calendar).first else { return }
        weekDate = date
        browsedWeeks.removeAll { $0 == monday }
        browsedWeeks.append(monday)
        if browsedWeeks.count > Self.maximumBrowsedWeeks {
            browsedWeeks.removeFirst(browsedWeeks.count - Self.maximumBrowsedWeeks)
        }
        rebuildDisplayDates()
    }

    /// App policy: weeks begin on Monday, independently of the locale's firstWeekday.
    static func week(containing date: Date, calendar: Calendar = .current) -> [Date] {
        let day = calendar.startOfDay(for: date)
        let offset = (calendar.component(.weekday, from: day) + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -offset, to: day) else { return [day] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func rebuildDisplayDates() {
        let anchors = scheduledDates + [today, weekDate] + browsedWeeks
        displayDates = Set(anchors.flatMap { Self.week(containing: $0, calendar: calendar) }).sorted()
    }
}
