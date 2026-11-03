import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(referenceDate: UITestConfiguration.referenceDate)
        }
        .modelContainer(for: ScheduleEvent.self, inMemory: UITestConfiguration.isEnabled) { result in
            #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            guard !UITestConfiguration.isEnabled,
                  environment["XCTestConfigurationFilePath"] == nil,
                  environment["XCTestBundlePath"] == nil,
                  environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1",
                  !ProcessInfo.processInfo.arguments.contains("-skipDemoData") else { return }
            do {
                let container = try result.get()
                try DemoScheduleData.seedIfEmpty(in: container)
            } catch {
                print("デモデータの初期登録に失敗しました: \(error)")
            }
            #endif
        }
    }
}
