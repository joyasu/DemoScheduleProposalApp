//
//  UITestConfiguration.swift
//  DemoScheduleProposalApp
//

//
//  デバッグ時のUIテスト用に、独立した保存先と固定の基準日時を設定する。

import Foundation

/// UI tests opt into an isolated, empty store. Release builds ignore these settings.
enum UITestConfiguration {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
        #else
        false
        #endif
    }

    static var referenceDate: Date? {
        guard isEnabled,
              let value = ProcessInfo.processInfo.environment["UI_TEST_NOW"],
              let timestamp = TimeInterval(value), timestamp.isFinite else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}
