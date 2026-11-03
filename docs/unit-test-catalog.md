# ユニットテスト一覧

更新日: 2026-11-02

モデル・ViewModel・サービスの振る舞いを確認する61項目の一覧。全項目に対応する Swift Testing のテストを実装済み。境界値や異常系はパラメーター化しているため、実行ケース数は一覧の項目数と異なる。

実行ケースは111件。[テスト全体の構成・実行記録](README.md)と[UIテスト一覧](ui-test-catalog.md)も参照。

## 管理方法

- テスト実装には Swift Testing を使用する。
- ID は固定し、テスト関数のコメントに対応する ID を記載する。項目を削除しても ID を再利用しない。
- 状態は「未実装」「準備待ち」「実装済み」で管理し、実装時にテストファイル・関数へのリンクを追加する。
- 実行結果は Xcode のテスト結果を正とする。この一覧には合否を固定記録しない。
- P1 は主要機能・既知不具合、P2 は補助機能・異常系。P1 から実装する。
- 「現行仕様」は現在のコードに基づく期待結果。「修正目標」は不具合修正後の期待結果。「要決定」は仕様を決めてから実装する。

## 日付と予定の表示用データ

| ID | 優先度 | 対象 | 条件・操作 | 期待結果 | 根拠 | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| DAY-001 | P1 | ScheduleEvent.isOngoing | 開始直前・開始と同時・終了直前・終了と同時 | 開始以上かつ終了未満だけ進行中 | 現行仕様 | 実装済み |
| DAY-002 | P1 | ScheduleEvent.isOngoing | 時間内の完了済み予定・終日予定 | どちらも進行中にならない | 現行仕様 | 実装済み |
| DAY-003 | P1 | ScheduleDay.upcoming | 過去・今日・未来の予定を順不同で渡す | 過去も保持し、日付昇順でまとめる | 現行仕様 | 実装済み |
| DAY-004 | P1 | ScheduleDay.upcoming | 前日開始で現在進行中の時間指定予定 | 今日のグループに入る | 現行仕様 | 実装済み |
| DAY-005 | P2 | ScheduleDay.upcoming | 同日に終日予定と時間指定予定が複数ある | 終日予定が先、同種は開始日時順 | 現行仕様 | 実装済み |
| DAY-006 | P1 | ScheduleDay.upcoming | 10月31日〜11月2日の終日予定を東京・ロサンゼルスのタイムゾーンで登録 | 夏時間の終了をまたいでも、10月31日・11月1日・2日の各グループに予定が含まれる | 修正済み・回帰テスト対象 | 実装済み |
| DAY-007 | P2 | ScheduleDay.upcoming | 空の予定配列 | 空のグループ配列 | 現行仕様 | 実装済み |
| CAL-001 | P2 | AgendaCalendarViewModel.week | 月曜・日曜・月末・年末を渡す | 対象日を含む月曜始まりの連続7日を返す | 現行仕様 | 実装済み |
| CAL-002 | P2 | AgendaCalendarViewModel.changeWeek | 前週・翌週へ移動 | weekDate が7日移動し、最近閲覧した最大12週が表示対象に残る | 現行仕様 | 実装済み |
| CAL-003 | P1 | AgendaCalendarViewModel.update/displayDates | 予定なし、または離れた週に予定あり | 今週・予定の週・閲覧した週を重複なく日付順に保持し、予定のない日も含める | 現行仕様 | 実装済み |

DAY-006 は複数日の終日予定が開始日にしか表示されなかった不具合の回帰テスト。終了日を含む各日への配置と、展開後の終日予定が提案区間の対象にならないことを確認する。

## 予定の編集と保存

| ID | 優先度 | 対象 | 条件・操作 | 期待結果 | 根拠 | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| EDT-001 | P1 | EventDraft | 既存予定から作成して下書きのタイトル等を変更 | 初期値がコピーされ、保存前は元の予定を変更しない | 現行仕様 | 実装済み |
| EDT-002 | P1 | EventEditorViewModel.isValid | タイトルが空・空白のみ・改行のみ | 保存不可 | 現行仕様 | 実装済み |
| EDT-003 | P1 | EventEditorViewModel.isValid | 時間指定予定の終了が開始より前・同時・後 | 前だけ無効。同時のゼロ時間予定は有効 | 現行仕様 | 実装済み |
| EDT-004 | P1 | EventEditorViewModel.isValid | 終日予定の終了日が開始日の前日・同日・翌日 | 前日だけ無効。同日内の時刻の大小は問わない | 現行仕様 | 実装済み |
| EDT-005 | P1 | EventEditorViewModel.start/end | 時間指定予定の片端を動かして開始と終了が逆転 | 編集した端を保持し、以前の所要時間で他方を移動 | 現行仕様 | 実装済み |
| EDT-006 | P1 | EventEditorViewModel.start/end | 終日予定の片端の日付を動かして逆転 | 編集した端を保持し、以前の日数差で他方を移動 | 現行仕様 | 実装済み |
| EDT-007 | P2 | EventEditorViewModel.start/end | 開始と終了が逆転しない範囲で編集 | 他方の日時は変わらない | 現行仕様 | 実装済み |
| EDT-008 | P1 | EventEditorViewModel.save | 有効な新規予定を保存 | 1件追加され、タイトルの前後空白を除去し、場所・メモも保存 | 現行仕様 | 実装済み |
| EDT-009 | P1 | EventEditorViewModel.save | 既存予定を編集して保存 | 件数を増やさず同じ予定を更新し、完了状態を維持 | 現行仕様 | 実装済み |
| EDT-010 | P1 | EventEditorViewModel.save | 終日予定を保存 | 開始・終了をそれぞれ当日の開始時刻に正規化 | 現行仕様 | 実装済み |
| EDT-011 | P1 | EventEditorViewModel.save | 無効な下書きを保存 | false を返し、データを追加・更新しない | 現行仕様 | 実装済み |
| EDT-012 | P1 | EventEditorViewModel.delete | 既存予定を削除／新規下書きを削除 | 既存は削除成功、新規は false で件数不変 | 現行仕様 | 実装済み |
| EDT-013 | P2 | EventEditorViewModel.persist | 保存または削除時に保存エラー | false、変更をロールバックし、エラー表示フラグを立てる | 現行仕様 | 実装済み |

## 空き区間の選択と提案計算

| ID | 優先度 | 対象 | 条件・操作 | 期待結果 | 根拠 | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| INT-001 | P1 | ProposalInterval.available | 空配列、または完了・終日・終了済みだけ | 区間を返さない。終了が now と同時の予定も対象外 | 現行仕様 | 実装済み |
| INT-002 | P1 | ProposalInterval.available | 次の予定まで空きがある | 現在から次の開始まで、from が nil の区間を返す | 現行仕様 | 実装済み |
| INT-003 | P1 | ProposalInterval.available | 現在進行中の予定と、その終了後の予定 | 進行中の予定の終了を起点にする | 現行仕様 | 実装済み |
| INT-004 | P1 | ProposalInterval.available | 隣接予定・重複予定・内包された予定 | 長さ0や重複中の空き区間を作らず、最も遅い終了から次の空きを作る | 現行仕様 | 実装済み |
| INT-005 | P1 | ProposalInterval.available | 順不同の予定、日付をまたぐ空き | 時系列で区間を返し、最後の予定の後には区間を作らない | 現行仕様 | 実装済み |
| SEL-001 | P1 | AgendaViewModel.beginSelection/cancelSelection | 選択がある状態で開始・キャンセル | どちらも選択を空にし、モードを適切に切り替える | 現行仕様 | 実装済み |
| SEL-002 | P1 | AgendaViewModel.validSelection | 選択後に予定変更・完了・時間経過で区間が無効になる | 現在も有効な区間だけ返す | 現行仕様 | 実装済み |
| SEL-003 | P1 | AgendaViewModel.execute | 有効な区間を複数選択／有効な選択なし | 選択した区間だけでリクエスト作成／新規リクエストなし | 現行仕様 | 実装済み |
| SEL-004 | P1 | AgendaViewModel.toggleCompletion | 未完了から完了、完了から未完了へ変更 | 状態を保存し、完了にした場合は選択を解除 | 現行仕様 | 実装済み |
| SEL-005 | P2 | AgendaViewModel.toggleCompletion | 保存エラー | 完了状態を戻してエラー表示フラグを立てる | 現行仕様 | 実装済み |
| GAP-001 | P1 | ProposalGap.planned | 移動後の到着が次の開始を超える | 移動・休憩を作らず、間に合わない旨と切り上げた所要分数を返す | 現行仕様 | 実装済み |
| GAP-002 | P1 | ProposalGap.planned | 到着が次の開始と同時、または開始10分前より後 | 移動を作り、10分の余裕がない旨を返す。休憩なし | 現行仕様 | 実装済み |
| GAP-003 | P1 | ProposalGap.planned | 到着が開始10分前と同時 | 準備時間確保のメッセージ。休憩なし | 現行仕様 | 実装済み |
| GAP-004 | P1 | ProposalGap.planned | 準備10分を引いた残りが4分59秒・5分・5分1秒 | 5分以上だけ休憩を作る。休憩は到着から開始10分前まで | 現行仕様 | 実装済み |
| GAP-005 | P2 | ProposalGap.planned | 移動時間0、場所の名称なし | 到着は出発と同時、移動の場所名には予定タイトルを使う | 現行仕様 | 実装済み |

SEL-003: update(events:now:calendar:) で元の予定と固定時刻から区間を生成する。選択判定と execute() はその区間配列を共有する。GAP・SVCの判定は表示文言ではなく、型で表現した失敗理由・注意事項を検証する。

## 保守性改善の回帰テスト

設計上の仕様は [予定表示・提案計算の設計](schedule-design.md) を参照。

| ID | 条件・操作 | 期待結果 | テスト実装 |
| --- | --- | --- | --- |
| MAINT-001 | 複数日の終日予定と時間指定予定を表示し、同じIDの予定を編集 | 提案は元データから生成され、編集後の内容・選択・行構成へ更新 | [agendaUpdatesSnapshotsAndPreparedRows](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-002 | 保持上限を超えて週移動 | 古い空の週を除外し、予定の週・今週・移動先は保持 | [calendarBoundsHistoryAndRetainsScheduledDates](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-003 | 東京・ロサンゼルスで夏時間終了をまたぐ終日予定を編集・保存・日別表示 | 注入したCalendarで正規化し、終了日を含め、月曜始まりを維持 | [allDayRoundTripUsesInjectedCalendar](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-004 | 表示中にCalendarのタイムゾーンを変更 | 日付キーを新しい日の開始時刻へ再生成 | [calendarChangeRebuildsDateKeys](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-005 | 逆転した休憩日時・負数や非有限値の移動時間 | 不正な休憩・提案を作らず型で失敗を返す | [typedResultsRejectInvalidIntervals](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-006 | 最初の区間の依存処理が通常エラーを投げる | 失敗理由を記録し、後続区間は継続 | [proposalFailureContinuesWithNextInterval](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-007 | 依存処理が直接CancellationErrorを投げる | 通常の失敗結果として表示しない | [proposalCancellationDoesNotBecomeFailure](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |
| MAINT-008 | 再読み込み後に古い処理が終了 | 新しい読み込み状態・結果を上書きしない | [supersededLoadCannotClearLoadingState](../DemoScheduleProposalAppUnitTests/MaintainabilityTests.swift) |

## 外部依存・提案結果・設定

| ID | 優先度 | 対象 | 条件・操作 | 期待結果 | 根拠 | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| RES-001 | P1 | ProposalResultViewModel.needsLocation | 場所なし・座標片方なし・範囲外・有効座標 | 有効な座標の組だけ場所設定不要 | 現行仕様 | 実装済み |
| RES-002 | P1 | ProposalResultViewModel.setLocation/resolved | ある予定の場所を設定 | 同じ ID の予定に反映し、他の予定は維持。再試行番号が増える | 現行仕様 | 実装済み |
| RES-003 | P1 | ProposalResultViewModel.load | 現在地起点あり／なし | ありの場合だけ現在地を取得し、各区間の結果を保存 | 現行仕様 | 実装済み |
| RES-004 | P1 | ProposalResultViewModel.load | 現在地取得が失敗 | 位置情報エラーを保持し、既存予定を起点とする区間は処理を続ける | 現行仕様 | 実装済み |
| RES-005 | P2 | ProposalResultViewModel.load | 再読み込み・キャンセル | 再読み込み時に以前の結果を消し、キャンセル後は新しい結果を書き込まない | 現行仕様 | 実装済み |
| SVC-001 | P1 | ProposalService.makeGap | 予定の時間重複、場所なし、不正座標 | 経路検索をせず、理由を返す | 現行仕様 | 実装済み |
| SVC-002 | P1 | ProposalService.makeGap | ETA成功・負数・非有限値・通信失敗 | 正常値で提案生成、それ以外は適切なエラーメッセージ | 現行仕様 | 実装済み |
| SVC-003 | P2 | ProposalService.makeGap | 経路検索中にキャンセル | 通常エラー扱いにせず CancellationError を返す | 現行仕様 | 実装済み |
| LOC-001 | P2 | LocationPickerViewModel.search | 空文字・前後空白のある query | searchText が空白を除去し、空検索は結果とメッセージを消す | 現行仕様 | 実装済み |
| LOC-002 | P1 | LocationPickerViewModel.search | 連続入力、検索成功・0件・エラー | 古い結果で新しい結果を上書きせず、結果または案内を表示 | 現行仕様 | 実装済み |
| LOC-003 | P1 | CurrentLocationService | 許可未決定・許可済み・拒否・制限 | 許可要求／位置取得／拒否エラーに分岐 | 現行仕様 | 実装済み |
| LOC-004 | P1 | CurrentLocationService | 位置なし・負の精度・120秒以上古い位置・有効な位置 | 無効な位置はエラー、有効な位置だけ返す | 現行仕様 | 実装済み |
| LOC-005 | P1 | CurrentLocationService | タイムアウト・キャンセル・遅れて届くコールバック | 継続を一度だけ完了し、取得処理とタイマーを停止 | 現行仕様 | 実装済み |
| SET-001 | P1 | SettingsViewModel.deleteAllData | DEBUG構成で複数件／0件を削除 | 成功し、保存済み予定が0件になる | 現行仕様 | 実装済み |
| SET-002 | P2 | SettingsViewModel.deleteAllData | fetch または save が失敗 | false、ロールバック、エラー表示フラグ | 現行仕様 | 実装済み |

## コード側の準備状況

- DAY-006: 終了日を含む各日に終日予定を配置する修正済み。Calendar を引数で指定可能。終日予定は既存の提案区間計算で除外されるため、複数日に配置しても提案対象にはならない。
- RES-003〜005: ProposalResultViewModel の初期化時に現在地取得・区間提案・現在時刻のクロージャを渡せる。
- LOC-003〜005: CurrentLocationManaging による位置情報マネージャーの差し替え、および現在時刻・タイムアウト待機のクロージャ指定が可能。
- SVC-002〜003、LOC-002: ETA取得・場所検索・入力待機のクロージャを差し替え可能。
- EDT-013、SEL-005、SET-002: 実際の ModelContext に対する変更とロールバックを使い、保存・取得のクロージャでエラーを注入。

## テスト構成と実行方法

- テストの日時・座標・文字列・境界値・パラメーター一覧・期待値は [StaticData/TestData.swift](../DemoScheduleProposalAppUnitTests/StaticData/TestData.swift) に集約する。新しい固定データもこのファイルの該当カテゴリに追加する。
- 予定・場所・日付・位置情報の生成と不正座標のデータは [StaticData/Fixtures.swift](../DemoScheduleProposalAppUnitTests/StaticData/Fixtures.swift) に置く。変更可能なモデルを static な共有インスタンスにせず、呼び出すたびに生成する。保存コンテキストや非同期制御の補助処理は TestSupport.swift に置く。
- ターゲットは DemoScheduleProposalAppUnitTests。Xcode の Product > Test（⌘U）で実行する。SET-001〜002 はアプリ側の機能と同じく DEBUG 構成で実行する。
- now は固定。終日予定の展開は東京とロサンゼルスのタイムゾーンを指定し、夏時間の終了をまたぐ日付でも検証する。Calendar.current を使う処理は、同じカレンダーからテスト用の日付を構築する。
- SwiftData の保存テストは各テスト専用のインメモリ ModelContainer を使用し、アプリの実データに触れない。保存後の fetch で件数・値を確認する。
- MainActor の ViewModel は MainActor 上で検証する。
- 通信・位置取得はテスト用の応答に差し替える。TestSignal と TestGate で開始・完了を同期し、ネットワーク・GPS・30秒の実待機に依存しない。非同期スイートには1分の制限を設定する。
- 保存失敗ではエラーを注入し、件数・元の値・変更状態・エラー表示フラグを検証する。成功時には別の ModelContext から保存済みデータを読み直す。
- UI表示、スクロール、シート操作、実際の位置情報許可ダイアログは別途 UI テスト／実機確認で扱う。現在のUIテストは追加・編集キャンセル・更新・削除の4本。DAY-006 は日別データを検証済みだが、「予定はありません」の誤表示がないことを確認するUIテストは未実装。

## 実装リンク

| ID | テスト実装 |
| --- | --- |
| DAY-001 | [ongoingBoundaries](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-002 | [completedAndAllDayAreNotOngoing](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-003 | [groupingRetainsPastAndMovesOngoingEventsToToday](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-004 | [groupingRetainsPastAndMovesOngoingEventsToToday](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-005 | [groupingRetainsPastAndMovesOngoingEventsToToday](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-006 | [allDayEventsAppearOnEveryDate](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| DAY-007 | [groupingRetainsPastAndMovesOngoingEventsToToday](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| CAL-001 | [weeksStartOnMonday](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| CAL-002 | [browsedAndScheduledWeeksRemainVisible](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| CAL-003 | [browsedAndScheduledWeeksRemainVisible](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| EDT-001 | [draftCopiesValuesWithoutEditingOriginal](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-002 | [blankTitleCannotSave](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-003 | [timedDateValidation](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-004 | [allDayValidationIgnoresTimeOfDay](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-005 | [crossingTimedEndpointPreservesDuration](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-006 | [crossingAllDayEndpointPreservesDayCount](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-007 | [nonCrossingEditsKeepOtherEndpoint](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-008 | [savingNewDraftPersistsTrimmedFields](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-009 | [savingExistingEventKeepsIdentityAndCompletion](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-010 | [allDaySaveNormalizesBothDates](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-011 | [invalidDraftDoesNotWrite](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-012 | [deletingExistingAndUnsavedDrafts](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| EDT-013 | [persistenceFailureRollsBack](../DemoScheduleProposalAppUnitTests/EventEditorTests.swift) |
| INT-001 | [excludedEventsDoNotProduceIntervals](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| INT-002 | [firstIntervalStartsNow](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| INT-003 | [overlappingAndAdjacentEventsUseLatestEnd](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| INT-004 | [overlappingAndAdjacentEventsUseLatestEnd](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| INT-005 | [intervalsAreOrderedAndHaveNoTrailingGap](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| SEL-001 | [selectionLifecycleClearsSelection](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| SEL-002 | [invalidSelectionsAreExcluded](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| SEL-003 | [executionUsesSuppliedTimeAndSelectedIntervals](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| SEL-004 | [completingPersistsAndClearsSelection](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| SEL-005 | [completionFailureRestoresStateAndSelection](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| GAP-001 | [lateArrivalReturnsWarningWithoutTravel](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| GAP-002 | [arrivalMarginBoundaries](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| GAP-003 | [arrivalMarginBoundaries](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| GAP-004 | [arrivalMarginBoundaries](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| GAP-005 | [zeroTravelUsesEventTitlesWhenLocationsAreAbsent](../DemoScheduleProposalAppUnitTests/ScheduleModelTests.swift) |
| RES-001 | [locationValidity](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift) |
| RES-002 | [settingLocationOnlyUpdatesMatchingID](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift) |
| RES-003 | [loadUsesLocationOnlyForCurrentOrigin](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift) |
| RES-004 | [locationFailureStillLoadsScheduledIntervals](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift) |
| RES-005 | [reloadClearsResultsAndCancelledResponseIsDiscarded](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift)<br>[cancelledLocationDoesNotWriteOriginOrError](../DemoScheduleProposalAppUnitTests/DemoScheduleProposalAppUnitTests.swift) |
| SVC-001 | [invalidGapsNeverRequestDirections](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift) |
| SVC-002 | [validETAUsesCarDepartureAndEndpoints](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift)<br>[invalidETAIsRejected](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift)<br>[networkFailureReturnsRetryMessage](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift) |
| SVC-003 | [cancelledDirectionsThrowCancellation](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift) |
| LOC-001 | [emptySearchClearsStateWithoutCallingService](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift) |
| LOC-002 | [searchOutcomes](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift)<br>[cancelledOldSearchCannotOverwriteNewResults](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift)<br>[cancellationDuringDebounceSkipsNetwork](../DemoScheduleProposalAppUnitTests/SearchServiceTests.swift) |
| LOC-003 | [authorizedRequestReturnsLocation](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift)<br>[deniedAuthorizationDoesNotRequestLocation](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift) |
| LOC-004 | [validatesPositionQualityAndAge](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift) |
| LOC-005 | [timeoutCompletesRequestWithoutRealWaiting](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift)<br>[cancellationStopsLocationAndTimeout](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift)<br>[locationFailureStopsRequestAndAllowsRetry](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift)<br>[simultaneousRequestDoesNotReplacePendingContinuation](../DemoScheduleProposalAppUnitTests/CurrentLocationTests.swift) |
| SET-001 | [deleteAllDataPersistsEmptyStore](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
| SET-002 | [deleteAllFailureRestoresStore](../DemoScheduleProposalAppUnitTests/AgendaAndSettingsTests.swift) |
