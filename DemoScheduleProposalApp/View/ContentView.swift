import SwiftUI
import SwiftData

struct ContentView: View {
    var referenceDate: Date? = nil
    @Environment(\.calendar) private var calendar
    @Query(sort: \ScheduleEvent.start) private var events: [ScheduleEvent]
    @State private var draft: EventDraft?
    @State private var showsSettings = false
    @State private var agendaID = UUID()

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                let now = referenceDate ?? timeline.date
                AgendaView(events: events, now: now) { event in
                    draft = EventDraft(event: event)
                } add: {
                    draft = EventDraft(now: referenceDate ?? .now)
                }
            }
            .id(agendaID)

            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("設定", systemImage: "line.3.horizontal") {
                        showsSettings = true
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(item: $draft) { item in
                EventEditor(draft: item)
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView {
                draft = nil
                agendaID = UUID()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .environment(\.timeZone, calendar.timeZone)
        .tint(.teal)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScheduleEvent.self, inMemory: true)
}
