//
//  EventCard.swift
//  DemoScheduleProposalApp
//

//
//  予定のタイトル、日時、場所、メモを通常または提案用のカードとして表示する。

import SwiftUI

struct EventCard: View {
    let title: String
    let start: Date
    let end: Date
    var isAllDay = false
    var locationName: String?
    var memo = ""
    var mode: CardDisplayMode = .standard
    var setLocation: (() -> Void)?

    var body: some View {
        ScheduleCardFrame(title: "予定", symbol: "calendar", mode: mode) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                EventTimeLabel(start: start, end: end, isAllDay: isAllDay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let locationName, !locationName.isEmpty {
                    Label(locationName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let setLocation {
                    Button(action: setLocation) {
                        Label("設定する", systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                    }
                    .accessibilityLabel("場所を設定する")
                }
                if !memo.isEmpty {
                    Text(memo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
