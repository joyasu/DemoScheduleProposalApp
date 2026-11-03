//
//  UITestData.swift
//  DemoScheduleProposalApp
//

//
//  UIテストで使用する起動設定、入力値、画面要素の識別子を定義する。

import Foundation

enum UITestData {
    static let timeout: TimeInterval = 10
    static let maximumScrolls = 4
    static let expectedEventCount = 1
    static let emptyEventCount = 0
    static let missingTitleMessage = "Title field did not expose its current text"
    static let launchArguments = ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    static let launchEnvironment = ["UI_TEST_NOW": "1793588400"]
    static let rowTitlePredicate = "label CONTAINS %@"
    static let createdTitle = "UI Added Event"
    static let originalTitle = "UI Original Event"
    static let cancelledTitle = "UI Unsaved Event"
    static let updatedTitle = "UI Updated Event"
    static let deletedTitle = "UI Delete Event"
    static let failureScreenshotName = "UI test failure"

    enum Identifier {
        static let add = "agenda.addEvent"
        static let event = "agenda.event"
        static let title = "eventEditor.title"
        static let save = "eventEditor.save"
        static let cancel = "eventEditor.cancel"
        static let delete = "eventEditor.delete"
        static let confirmDelete = "eventEditor.confirmDelete"
    }
}
