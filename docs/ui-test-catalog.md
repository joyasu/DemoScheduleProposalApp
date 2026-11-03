# UIテスト一覧

更新日: 2026-11-02

XCTest・XCUIAutomationで実際にアプリを操作する。テストターゲットは `DemoScheduleProposalAppUITests`。

4フローとも実装済み。[テスト全体の構成・実行記録](README.md)と[ユニットテスト一覧](unit-test-catalog.md)も参照。

| ID | テスト | 操作 | 期待結果 | 実装 |
| --- | --- | --- | --- | --- |
| UI-001 | 予定の追加 | 追加画面を開き、タイトルを入力して保存 | 空タイトルでは保存不可。保存後は一覧に1件表示され、開き直しても入力内容が保持される | `testCreateEvent` |
| UI-002 | 編集のキャンセル | 作成済みの予定を開き、タイトル変更後にキャンセル | 一覧と開き直した編集画面に元のタイトルが残り、変更したタイトルは表示されない | `testCancelEditingKeepsOriginalTitle` |
| UI-003 | 予定の更新 | 作成済みの予定を開き、タイトルを変更して保存 | 一覧と開き直した編集画面に更新後のタイトルが表示され、件数は1件のまま | `testUpdateEventTitle` |
| UI-004 | 予定の削除 | 作成済みの予定を開き、削除ボタンと確認ダイアログの削除を押す | 編集画面が閉じ、一覧から予定が消えて0件になる | `testDeleteEvent` |

## ファイル

- [テスト本体](../DemoScheduleProposalAppUITests/DemoScheduleProposalAppUITests.swift)
- [固定データ・操作対象の識別子](../DemoScheduleProposalAppUITests/StaticData/UITestData.swift)
- [アプリ側のテスト起動設定](../DemoScheduleProposalApp/Service/UITestConfiguration.swift)

## 実行方法と前提

- XcodeのTest NavigatorでUIテストターゲットを選んで実行する。⌘Uではユニットテストも含めて実行する。
- Debug構成で `-uiTesting` を指定した場合のみ、アプリは空のインメモリSwiftDataコンテナを使用する。通常の保存領域は使用せず、デモ予定の投入も行わない。Release構成ではこの切り替えを無効にする。
- 各テストはアプリを新しく起動し、必要な予定を画面操作で作成する。他のテストの実行結果に依存しない。
- `UI_TEST_NOW` に固定時刻を渡し、一覧の基準日時と新規予定の初期日時をそろえる。入力タイトル・待機上限・起動設定は `StaticData` で管理する。
- UIテストの起動設定では言語を英語、ロケールを `en_US` に指定する。固定入力は英字タイトルを使用する。実行端末のタイムゾーン自体は変更しない。
- 操作対象は `accessibilityIdentifier` で指定する。固定時間のsleepではなく、要素の出現・消滅を待つ。
- 削除確認は `app.sheets` 内の識別子に一致するボタンの `firstMatch` を操作する。SwiftUIが同じボタンを親子の2要素として公開する場合にも対象を選べるようにする。
- 失敗時はスクリーンショットをXcodeのテスト結果へ添付する。
- 今回はタイトルの追加・変更・キャンセル・削除の4フローが対象。日付ピッカーの操作、アプリ再起動後の永続化、通信・GPS、終日予定、週移動は別の追加テストで扱う。

## アプリ側の対応箇所

| ファイル | 対応内容 |
| --- | --- |
| [UITestConfiguration.swift](../DemoScheduleProposalApp/Service/UITestConfiguration.swift) | Debug時のテスト起動判定と固定時刻の読み込み |
| [MyApp.swift](../DemoScheduleProposalApp/MyApp.swift) | 専用のインメモリ保存領域への切り替えとデモデータ投入の抑止 |
| [ContentView.swift](../DemoScheduleProposalApp/View/ContentView.swift) | 一覧と新規予定に同じ固定時刻を渡す |
| [EventDraft.swift](../DemoScheduleProposalApp/Model/EventDraft.swift) | 初期日時を指定できる `now` 引数。通常起動時は現在時刻を使う |
| [AgendaView.swift](../DemoScheduleProposalApp/View/AgendaView/AgendaView.swift)・[AgendaEventRow.swift](../DemoScheduleProposalApp/View/AgendaView/Helpers/AgendaEventRow.swift) | 追加ボタン・予定行の識別子 |
| [EventEditor.swift](../DemoScheduleProposalApp/View/AgendaView/Helpers/EventEditor.swift) | タイトル欄・保存・キャンセル・削除・削除確認の識別子 |
