import SwiftUI

struct ProposalIntervalRow: View {
    let interval: ProposalInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("この区間に提案", systemImage: "sparkles")
                .foregroundStyle(.teal)
            EventTimeLabel(start: interval.start, end: interval.to.start, isAllDay: false)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .tag(interval.id)
        .accessibilityElement(children: .combine)
    }
}
