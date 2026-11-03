import SwiftUI
import SwiftData

struct AgendaEventRow: View {
    let event: ScheduleEvent
    let now: Date
    let isSelecting: Bool
    let edit: (ScheduleEvent) -> Void
    let toggleCompletion: (ScheduleEvent) -> Void

    var body: some View {
        Group {
            if isSelecting {
                EventCard(title: event.title, start: event.start, end: event.end,
                          isAllDay: event.isAllDay, locationName: event.location?.name, memo: event.memo)
            } else {
                Button { edit(event) } label: { EventRow(event: event) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("agenda.event")
            }
        }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                Button {
                    toggleCompletion(event)
                } label: {
                    if event.isCompleted {
                        Label("未完了に戻す", systemImage: "arrow.uturn.backward")
                    } else {
                        Label("完了", systemImage: "checkmark")
                    }
                }
                .tint(.teal)
            }
        }
        .overlay(alignment: .topTrailing) {
            if event.isCompleted {
                Label("完了", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .allowsHitTesting(false)
            } else if event.isOngoing(at: now) {
                Label("今", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.teal)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .tag(AgendaSelectionID.event(event.persistentModelID))
        .selectionDisabled(true)
        .opacity(event.isCompleted ? 0.5 : 1)
    }
}
