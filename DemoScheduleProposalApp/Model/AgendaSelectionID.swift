import SwiftData

enum AgendaSelectionID: Hashable {
    case now
    case event(PersistentIdentifier)
}
