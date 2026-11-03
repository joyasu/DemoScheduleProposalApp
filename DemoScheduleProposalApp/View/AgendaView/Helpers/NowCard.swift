import SwiftUI

struct NowCard: View {
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.teal)
                .accessibilityHidden(true)
            Text("今")
                .font(.headline)
            Spacer()
            Text(now, format: .dateTime.hour().minute())
                .font(.headline.monospacedDigit())
        }
        .padding()
        .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
