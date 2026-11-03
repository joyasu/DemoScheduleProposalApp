import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    var showsDeletionError = false

    #if DEBUG
    func deleteAllData(
        in context: ModelContext,
        fetchEvents: (ModelContext) throws -> [ScheduleEvent] = { try $0.fetch(FetchDescriptor<ScheduleEvent>()) },
        saveChanges: (ModelContext) throws -> Void = { try $0.save() }
    ) -> Bool {
        do {
            // ScheduleEvent is the app's only persisted model.
            let events = try fetchEvents(context)
            for event in events {
                context.delete(event)
            }
            try saveChanges(context)
            return true
        } catch {
            context.rollback()
            showsDeletionError = true
            return false
        }
    }
    #endif
}
