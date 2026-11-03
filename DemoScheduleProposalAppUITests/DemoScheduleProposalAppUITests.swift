//
//  DemoScheduleProposalAppUITests.swift
//  DemoScheduleProposalApp
//

//
//  画面操作を通じて予定の作成・編集・削除などを検証するUIテスト。

import XCTest
import XCUIAutomation

final class DemoScheduleProposalAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    override func tearDownWithError() throws {
        if let testRun, !testRun.hasSucceeded {
            let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
            attachment.name = UITestData.failureScreenshotName
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCUIApplication().terminate()
    }

    // UI-001
    // 空の状態から追加画面を開き、空タイトルでは保存できないことを確認してからタイトルを入力して保存する。
    // 一覧に1件だけ表示され、開き直した編集画面でも入力したタイトルが保持されることを確認する。
    @MainActor
    func testCreateEvent() throws {
        let app = launchEmptyApp()
        createEvent(UITestData.createdTitle, in: app)
        XCTAssertEqual(eventRows(in: app).count, UITestData.expectedEventCount)
        openEvent(UITestData.createdTitle, in: app)
        XCTAssertEqual(titleField(in: app).value as? String, UITestData.createdTitle)
    }

    // UI-002
    // 画面操作で作成した予定のタイトルを変更してキャンセルし、一覧の件数と元のタイトルが維持されることを確認する。
    // 編集画面を開き直しても、キャンセルしたタイトルが反映されていないことを確認する。
    @MainActor
    func testCancelEditingKeepsOriginalTitle() throws {
        let app = launchEmptyApp()
        createEvent(UITestData.originalTitle, in: app)
        openEvent(UITestData.originalTitle, in: app)
        replaceTitle(with: UITestData.cancelledTitle, in: app)
        app.buttons[UITestData.Identifier.cancel].tap()
        waitForEditorToClose(in: app)

        XCTAssertTrue(eventRow(UITestData.originalTitle, in: app).waitForExistence(timeout: UITestData.timeout))
        XCTAssertFalse(eventRow(UITestData.cancelledTitle, in: app).exists)
        XCTAssertEqual(eventRows(in: app).count, UITestData.expectedEventCount)
        openEvent(UITestData.originalTitle, in: app)
        XCTAssertEqual(titleField(in: app).value as? String, UITestData.originalTitle)
    }

    // UI-003
    // 画面操作で作成した予定のタイトルを変更して保存し、一覧が1件のまま新しいタイトルへ更新されることを確認する。
    // 編集画面を開き直しても保存したタイトルが表示されることを確認する。
    @MainActor
    func testUpdateEventTitle() throws {
        let app = launchEmptyApp()
        createEvent(UITestData.originalTitle, in: app)
        openEvent(UITestData.originalTitle, in: app)
        replaceTitle(with: UITestData.updatedTitle, in: app)
        app.buttons[UITestData.Identifier.save].tap()
        waitForEditorToClose(in: app)

        XCTAssertTrue(eventRow(UITestData.updatedTitle, in: app).waitForExistence(timeout: UITestData.timeout))
        XCTAssertFalse(eventRow(UITestData.originalTitle, in: app).exists)
        XCTAssertEqual(eventRows(in: app).count, UITestData.expectedEventCount)
        openEvent(UITestData.updatedTitle, in: app)
        XCTAssertEqual(titleField(in: app).value as? String, UITestData.updatedTitle)
    }

    // UI-004
    // 画面操作で作成した予定を開き、削除ボタンと確認ダイアログの削除を押す。
    // 編集画面が閉じて一覧が0件になり、追加ボタンを操作できることを確認する。
    @MainActor
    func testDeleteEvent() throws {
        let app = launchEmptyApp()
        createEvent(UITestData.deletedTitle, in: app)
        openEvent(UITestData.deletedTitle, in: app)
        let delete = app.buttons[UITestData.Identifier.delete]
        for _ in 0..<UITestData.maximumScrolls {
            if delete.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        // SwiftUI may expose both the containing button and its nested label as buttons.
        let confirmation = app.sheets.buttons.matching(identifier: UITestData.Identifier.confirmDelete).firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: UITestData.timeout))
        confirmation.tap()
        waitForEditorToClose(in: app)

        XCTAssertTrue(eventRow(UITestData.deletedTitle, in: app).waitForNonExistence(timeout: UITestData.timeout))
        XCTAssertEqual(eventRows(in: app).count, UITestData.emptyEventCount)
        XCTAssertTrue(app.buttons[UITestData.Identifier.add].isHittable)
    }

    @MainActor
    private func launchEmptyApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = UITestData.launchArguments
        app.launchEnvironment = UITestData.launchEnvironment
        app.launch()
        XCTAssertTrue(app.buttons[UITestData.Identifier.add].waitForExistence(timeout: UITestData.timeout))
        XCTAssertEqual(eventRows(in: app).count, UITestData.emptyEventCount)
        return app
    }

    @MainActor
    private func createEvent(_ title: String, in app: XCUIApplication) {
        app.buttons[UITestData.Identifier.add].tap()
        let field = titleField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: UITestData.timeout))
        let save = app.buttons[UITestData.Identifier.save]
        XCTAssertFalse(save.isEnabled)
        field.tap()
        field.typeText(title)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        waitForEditorToClose(in: app)
        XCTAssertTrue(eventRow(title, in: app).waitForExistence(timeout: UITestData.timeout))
    }

    @MainActor
    private func openEvent(_ title: String, in app: XCUIApplication) {
        let row = eventRow(title, in: app)
        XCTAssertTrue(row.waitForExistence(timeout: UITestData.timeout))
        row.tap()
        XCTAssertTrue(titleField(in: app).waitForExistence(timeout: UITestData.timeout))
    }

    @MainActor
    private func replaceTitle(with title: String, in app: XCUIApplication) {
        let field = titleField(in: app)
        guard let current = field.value as? String else {
            XCTFail(UITestData.missingTitleMessage)
            return
        }
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + title)
        XCTAssertEqual(field.value as? String, title)
    }

    @MainActor
    private func waitForEditorToClose(in app: XCUIApplication) {
        XCTAssertTrue(titleField(in: app).waitForNonExistence(timeout: UITestData.timeout))
    }

    @MainActor
    private func titleField(in app: XCUIApplication) -> XCUIElement {
        app.textFields[UITestData.Identifier.title]
    }

    @MainActor
    private func eventRows(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(identifier: UITestData.Identifier.event)
    }

    @MainActor
    private func eventRow(_ title: String, in app: XCUIApplication) -> XCUIElement {
        eventRows(in: app).matching(NSPredicate(format: UITestData.rowTitlePredicate, title)).firstMatch
    }
}
