import SwiftUI

struct EventRow: View {
    let event: ScheduleEvent

    var body: some View {
        EventCard(
            title: event.title,
            start: event.start,
            end: event.end,
            isAllDay: event.isAllDay,
            locationName: event.location?.name,
            memo: event.memo
        )
        .accessibilityHint("タップして予定を編集")
    }
}
