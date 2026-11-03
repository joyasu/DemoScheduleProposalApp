//
//  TestData.swift
//  DemoScheduleProposalApp
//

//
//  単体テストで共有する入力値、境界値、期待値などの定数を定義する。

import Foundation
import CoreLocation

/// Immutable inputs and expected values shared by unit tests.
/// Model objects are created by Fixtures for each test to avoid shared mutable state.
enum TestData {
    static let booleanCases = [true, false]
    static let suiteTimeoutMinutes = 1

    enum Count {
        static let none = 0
        static let single = 1
        static let pair = 2
        static let triple = 3
    }

    enum Time {
        static let epoch: TimeInterval = 1_800_000_000
        static let historicalEpoch: TimeInterval = 1000
        static let origin: TimeInterval = 0
        static let oneMinute: TimeInterval = 60
        static let fiveMinutes: TimeInterval = 300
        static let tenMinutes: TimeInterval = 600
        static let twentyMinutes: TimeInterval = 1200
        static let thirtyMinutes: TimeInterval = 1800
        static let fortyMinutes: TimeInterval = 2400
        static let fiftyMinutes: TimeInterval = 3000
        static let oneHour: TimeInterval = 3600
        static let seventyMinutes: TimeInterval = 4200
        static let twoHours: TimeInterval = 7200
        static let oneDay: TimeInterval = 86400
        static let nextDayEnd: TimeInterval = 87000
        static let lateTravel: TimeInterval = 601
        static let preparation: TimeInterval = 600
        static let minimumMarginForRest: TimeInterval = 900
        static let cancellableWait: Duration = .seconds(3600)
    }

    enum Dates {
        static let today = DateComponents(year: 2026, month: 11, day: 1, hour: 12)
        static let yesterday = DateComponents(year: 2026, month: 10, day: 31, hour: 12)
        static let tomorrow = DateComponents(year: 2026, month: 11, day: 2, hour: 12)
        static let allDayEnd = DateComponents(year: 2026, month: 11, day: 3, hour: 12)
        static let shiftedStart = DateComponents(year: 2026, month: 11, day: 10, hour: 12)
        static let shiftedEnd = DateComponents(year: 2026, month: 10, day: 31, hour: 12)
        static let saveStart = DateComponents(year: 2026, month: 11, day: 1, hour: 18)
        static let saveEnd = DateComponents(year: 2026, month: 11, day: 3, hour: 9)
        static let distant = DateComponents(year: 2026, month: 12, day: 15, hour: 12)
        static let midnight = 0
        static let sameDayOffset = 0
        static let dayOffsets = [-1, 0, 1]
        static let allDayDuration = 2
        static let expectedAllDayDates = [yesterday, today, tomorrow]
        static let timeZones = ["Asia/Tokyo", "America/Los_Angeles"]
        static let weekDates = [
            DateComponents(year: 2026, month: 11, day: 2, hour: 12),
            DateComponents(year: 2026, month: 11, day: 8, hour: 12),
            DateComponents(year: 2026, month: 12, day: 31, hour: 12),
            DateComponents(year: 2027, month: 1, day: 1, hour: 12)
        ]
        static let daysPerWeek = 7
        static let mondayWeekday = 2
        static let consecutiveDays = 1
        static let previousWeekOffset = -1
        static let forwardWeekOffset = 2
        static let previousWeekDays = -7
        static let nextWeekDays = 7
    }

    enum Text {
        static let empty = ""
        static let whitespace = " "
        static let title = "予定"
        static let memo = "メモ"
        static let location = "東京"
        static let address = "東京都"
        static let draft = "下書き"
        static let changed = "変更"
        static let allDay = "終日"
        static let paddedTitle = " \n新規予定\t "
        static let newTitle = "新規予定"
        static let savedMemo = "保存するメモ"
        static let updated = "更新"
        static let updatedMemo = "更新メモ"
        static let past = "過去"
        static let ongoing = "進行中"
        static let future = "未来"
        static let today = "今日"
        static let contained = "内包"
        static let overlap = "重複"
        static let adjacent = "隣接"
        static let next = "次"
        static let first = "最初"
        static let nextDay = "翌日"
        static let departure = "出発"
        static let arrival = "到着"
        static let other = "別"
        static let replacementLocation = "新しい場所"
        static let currentLocation = "現在地"
        static let currentLocationFixture = "現在地テスト"
        static let replacementDestination = "変更した行き先"
        static let loaded = "取得成功"
        static let success = "成功"
        static let previousResult = "以前の結果"
        static let cancelledResult = "キャンセル後の結果"
        static let unexpectedResult = "不要"
        static let paddedQuery = " \n東京\t "
        static let blankQuery = " \n "
        static let previousMessage = "以前の案内"
        static let latest = "最新"
        static let oldQuery = "古い"
        static let newQuery = "新しい"
        static let oldResult = "古い結果"
    }

    enum Message {
        static let roundedTravelMinutes = "11分"
        static let tooLate = "間に合いません"
        static let insufficientMargin = "余裕はありません"
        static let preparationReserved = "準備時間を確保"
        static let overlap = "重なって"
        static let missingLocation = "場所"
        static let invalidTravel = "有効な移動時間"
        static let retry = "再試行"
        static let noSearchResults = "見つかりません"
        static let searchFailed = "検索できません"
    }

    enum Schedule {
        static let ongoingOffsets: [TimeInterval] = [-1, 0, 599, 600]
        static let arrivalMargins: [TimeInterval] = [0, 1, 599, 600, 899, 900, 901]
        static let groupedTitles = [[Text.past], [Text.allDay, Text.ongoing, Text.today], [Text.future]]
        static let orderedTitles = [Text.first, Text.nextDay]
    }

    enum Editor {
        static let blankTitles = ["", " ", "\n\t"]
        static let durationCases: [TimeInterval] = [-1, 0, 1]
        static let insertOperation = "insert"
        static let updateOperation = "update"
        static let deleteOperation = "delete"
        static let persistenceOperations = [insertOperation, updateOperation, deleteOperation]
    }

    enum Agenda {
        static let completedReason = "completed"
        static let elapsedReason = "elapsed"
        static let changedReason = "changed"
        static let invalidSelectionReasons = [completedReason, elapsedReason, changedReason]
        static let eventIndices = [0, 1, 2]
        static let deletionCounts = [0, 3]
    }

    enum Search {
        static let invalidDurations = [-1.0, Double.infinity, -Double.infinity, Double.nan]
        static let successOutcome = "success"
        static let emptyOutcome = "empty"
        static let errorOutcome = "error"
        static let outcomes = [successOutcome, emptyOutcome, errorOutcome]
    }

    enum Location {
        static let latitude = 35.6812
        static let longitude = 139.7671
        static let altitude: CLLocationDistance = 0
        static let accuracy: CLLocationAccuracy = 100
        static let verticalAccuracy: CLLocationAccuracy = 0
        static let invalidAccuracy: CLLocationAccuracy = -1
        static let exactAccuracy: CLLocationAccuracy = 0
        static let ageLimit: TimeInterval = 120
        static let validAge: TimeInterval = 119
        static let missing = "missing"
        static let negativeAccuracy = "negativeAccuracy"
        static let stale = "stale"
        static let future = "future"
        static let fresh = "fresh"
        static let justFresh = "justFresh"
        static let qualityScenarios = [missing, negativeAccuracy, stale, future, fresh, justFresh]
        static let permittedStatuses: [CLAuthorizationStatus] = [.notDetermined, .authorizedWhenInUse, .authorizedAlways]
        static let deniedStatuses: [CLAuthorizationStatus] = [.denied, .restricted]
    }
}
