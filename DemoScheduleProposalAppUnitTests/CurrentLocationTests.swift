//
//  CurrentLocationTests.swift
//  DemoScheduleProposalApp
//

//
//  現在地取得の権限処理、位置情報の検証、失敗時の動作を検証するテスト。

import Foundation
import CoreLocation
import Testing
@testable import DemoScheduleProposalApp

@Suite(.timeLimit(.minutes(TestData.suiteTimeoutMinutes)))
@MainActor
struct CurrentLocationTests {
    // LOC-003
    // 許可未決定・使用中のみ許可・常時許可の各状態から位置を取得し、必要な場合だけ許可を要求して有効な座標を返すことを確認する。
    @Test(arguments: TestData.Location.permittedStatuses)
    func authorizedRequestReturnsLocation(status: CLAuthorizationStatus) async throws {
        let manager = FakeLocationManager()
        manager.authorizationStatus = status
        let service = CurrentLocationService(manager: manager, now: { Fixtures.now })
        let task = Task { try await service.currentLocation() }
        if status == .notDetermined {
            await manager.authorizationRequested.wait()
            #expect(manager.locationRequests == TestData.Count.none)
            manager.authorize(.authorizedWhenInUse)
        }
        await manager.requested.wait()
        manager.deliver([Fixtures.position()])
        let result = try await task.value
        #expect(result.name == TestData.Text.currentLocation)
        #expect(result.latitude == TestData.Location.latitude && result.longitude == TestData.Location.longitude)
        #expect(manager.authorizationRequests == (status == .notDetermined ? TestData.Count.single : TestData.Count.none))
        #expect(manager.locationRequests == TestData.Count.single && manager.stops == TestData.Count.single)
        #expect(manager.desiredAccuracy == kCLLocationAccuracyHundredMeters)
    }

    // LOC-003
    // 位置情報の利用が拒否・制限されている場合、許可要求や位置取得を行わず拒否エラーを返すことを確認する。
    @Test(arguments: TestData.Location.deniedStatuses)
    func deniedAuthorizationDoesNotRequestLocation(status: CLAuthorizationStatus) async {
        let manager = FakeLocationManager()
        manager.authorizationStatus = status
        let service = CurrentLocationService(manager: manager)
        let error = await #expect(throws: CurrentLocationError.self) {
            try await service.currentLocation()
        }
        #expect(error?.localizedDescription == CurrentLocationError.denied.localizedDescription)
        #expect(manager.locationRequests == TestData.Count.none && manager.authorizationRequests == TestData.Count.none)
    }

    // LOC-004
    // 位置なし・負の精度・現在から前後120秒の位置を拒否し、現在の位置や119秒前の位置は受け入れて取得処理を停止することを確認する。
    @Test(arguments: TestData.Location.qualityScenarios)
    func validatesPositionQualityAndAge(scenario: String) async throws {
        let manager = FakeLocationManager()
        let service = CurrentLocationService(manager: manager, now: { Fixtures.now })
        let task = Task { try await service.currentLocation() }
        await manager.requested.wait()
        switch scenario {
        case TestData.Location.missing: manager.deliver([])
        case TestData.Location.negativeAccuracy: manager.deliver([Fixtures.position(accuracy: TestData.Location.invalidAccuracy)])
        case TestData.Location.stale: manager.deliver([Fixtures.position(age: TestData.Location.ageLimit)])
        case TestData.Location.future: manager.deliver([Fixtures.position(age: -TestData.Location.ageLimit)])
        case TestData.Location.justFresh: manager.deliver([Fixtures.position(age: TestData.Location.validAge)])
        default: manager.deliver([Fixtures.position(accuracy: TestData.Location.exactAccuracy)])
        }
        if scenario == TestData.Location.fresh || scenario == TestData.Location.justFresh {
            let result = try await task.value
            #expect(result.latitude == TestData.Location.latitude)
        } else {
            let error = await #expect(throws: CurrentLocationError.self) { try await task.value }
            #expect(error?.localizedDescription == CurrentLocationError.unavailable.localizedDescription)
        }
        #expect(manager.stops == TestData.Count.single)
    }

    // LOC-005
    // 待機処理を手動で完了させてタイムアウトを再現し、取得不可エラーと停止処理を確認する。
    // 完了後に位置更新や失敗通知が重複して届いても、継続を再開し直してクラッシュしないことを確認する。
    @Test func timeoutCompletesRequestWithoutRealWaiting() async {
        let manager = FakeLocationManager()
        let timeout = TestGate<Void>()
        let service = CurrentLocationService(
            manager: manager, now: { Fixtures.now },
            waitForTimeout: { try await timeout.wait() }
        )
        let task = Task { try await service.currentLocation() }
        await manager.requested.wait()
        await timeout.started.wait()
        timeout.resolve(.success(()))
        let error = await #expect(throws: CurrentLocationError.self) { try await task.value }
        #expect(error?.localizedDescription == CurrentLocationError.unavailable.localizedDescription)
        #expect(manager.stops == TestData.Count.single)
        // Duplicate delegate callbacks must not resume the completed continuation again.
        manager.deliver([Fixtures.position()])
        manager.fail()
    }

    // LOC-005
    // 位置取得をキャンセルするとCancellationErrorとなり、位置取得とタイムアウト待機が停止することを確認する。
    // 終了後の追加通知でも継続が二重に再開されないことを確認する。
    @Test func cancellationStopsLocationAndTimeout() async {
        let manager = FakeLocationManager()
        let timeoutStarted = TestSignal()
        let timeoutCancelled = TestSignal()
        let service = CurrentLocationService(
            manager: manager,
            waitForTimeout: {
                timeoutStarted.signal()
                do {
                    try await Task.sleep(for: TestData.Time.cancellableWait)
                } catch {
                    timeoutCancelled.signal()
                    throw error
                }
            }
        )
        let task = Task { try await service.currentLocation() }
        await manager.requested.wait()
        await timeoutStarted.wait()
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        await timeoutCancelled.wait()
        #expect(manager.stops == TestData.Count.single)
        manager.deliver([Fixtures.position()])
        manager.fail()
    }

    // LOC-005
    // 位置取得の失敗後、同じサービスで再試行すると新しい位置情報を正常に取得できることを確認する。
    @Test func locationFailureStopsRequestAndAllowsRetry() async throws {
        let manager = FakeLocationManager()
        let service = CurrentLocationService(manager: manager, now: { Fixtures.now })
        let first = Task { try await service.currentLocation() }
        await manager.requested.wait()
        manager.fail()
        await #expect(throws: CurrentLocationError.self) { try await first.value }

        let retryStarted = TestSignal()
        manager.onRequest = { retryStarted.signal() }
        let retry = Task { try await service.currentLocation() }
        await retryStarted.wait()
        manager.deliver([Fixtures.position()])
        let result = try await retry.value
        #expect(result.latitude == TestData.Location.latitude)
    }

    // LOC-005
    // 位置取得中の同じサービスへ再要求すると後からの要求だけが失敗し、最初の要求は結果を受け取れることを確認する。
    @Test func simultaneousRequestDoesNotReplacePendingContinuation() async throws {
        let manager = FakeLocationManager()
        let service = CurrentLocationService(manager: manager, now: { Fixtures.now })
        let first = Task { try await service.currentLocation() }
        await manager.requested.wait()
        await #expect(throws: CurrentLocationError.self) { try await service.currentLocation() }
        manager.deliver([Fixtures.position()])
        let result = try await first.value
        #expect(result.latitude == TestData.Location.latitude)
        #expect(manager.locationRequests == TestData.Count.single)
    }
}
