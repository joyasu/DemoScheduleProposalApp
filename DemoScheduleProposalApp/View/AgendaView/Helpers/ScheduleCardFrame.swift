//
//  ScheduleCardFrame.swift
//  DemoScheduleProposalApp
//

//
//  予定・移動カードに共通する枠や見出しを表示し、提案用の装飾を切り替える。

import SwiftUI

struct ScheduleCardFrame<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let mode: CardDisplayMode
    @ViewBuilder let content: Content

    private var accent: Color {
        mode == .suggested ? .indigo : .teal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if mode == .suggested {
                    Label("提案", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.12), in: Capsule())
                }
            }
            .foregroundStyle(accent)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(accent.opacity(mode == .suggested ? 0.08 : 0.04),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accent.opacity(0.4),
                              style: StrokeStyle(lineWidth: 1, dash: mode == .suggested ? [5, 4] : []))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
