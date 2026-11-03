# テストドキュメント

更新日: 2026-11-02

| 種類 | 一覧 | 実装範囲 | フレームワーク |
| --- | --- | --- | --- |
| ユニットテスト | [ユニットテスト一覧](unit-test-catalog.md) | 61項目・111実行ケース。モデル、ViewModel、保存処理、通信・位置情報の異常系 | Swift Testing |
| UIテスト | [UIテスト一覧](ui-test-catalog.md) | 4フロー。予定の追加、編集のキャンセル、更新、削除 | XCTest・XCUIAutomation |

## 実行する

関連仕様: [予定表示・提案計算の設計](schedule-design.md)

1. Xcodeで `DemoScheduleProposalApp` スキームと実行先のシミュレーターを選ぶ。
2. Debug構成で Product > Test（⌘U）を実行する。
3. 一部だけ実行するときはTest Navigatorで対象のターゲット・テストを選ぶ。
4. 結果や失敗時の添付画像はReport Navigatorのテスト結果から確認する。

UIテストは起動引数を自動設定し、空のインメモリ保存領域を使う。普段使う予定データを削除・変更しない。ユニットテストもテストごとのインメモリ保存領域を使う。

## 固定データの管理

- [ユニットテストのStaticData](../DemoScheduleProposalAppUnitTests/StaticData/TestData.swift)：日時・座標・文字列・境界値・期待値。
- [ユニットテストのFixtures](../DemoScheduleProposalAppUnitTests/StaticData/Fixtures.swift)：テストごとに新しい予定や場所のデータを生成する。
- [UIテストのStaticData](../DemoScheduleProposalAppUITests/StaticData/UITestData.swift)：入力タイトル・起動設定・待機上限・要素識別子。

固定値を追加するときは各ターゲットの `StaticData` に置き、対応する一覧にも操作・期待結果・実装へのリンクを追加する。

## 実行記録（2026-11-02）

全体実行では103ケース中102成功、削除UIテスト1件が失敗した。確認ダイアログのボタンが親子の2要素として検出されたため、検索範囲をダイアログ内に絞り、最初の一致要素を選ぶよう修正した。

修正後、削除UIテストを単独で再実行し成功した。これにより、ユニットテスト99ケースとUIテスト4ケースそれぞれの成功を確認済み。修正後の全103ケース一括再実行は行っていない。

この記録は上記実行時点の結果。最新の合否はXcodeで再実行して確認する。

## 今後のUIテスト対象

日付ピッカーの操作、複数日の終日予定、週移動、提案区間の選択、アプリ再起動後の永続化、通信・GPSを使う画面は未実装。今回の4本の検証範囲には含まれない。
