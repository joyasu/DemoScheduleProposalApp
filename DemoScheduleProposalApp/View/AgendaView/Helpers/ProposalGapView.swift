//
//  ProposalGapView.swift
//  DemoScheduleProposalApp
//

//
//  空き区間への移動・休憩の提案と、関連する案内メッセージを表示する。

import SwiftUI

struct ProposalGapView: View {
    let gap: ProposalGap

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let plan = gap.plan {
                TravelCard(travel: plan.travel, mode: .suggested)
                Text("車での移動時間の目安です。交通状況により変わります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let rest = plan.rest {
                    EventCard(title: "到着先でひと休み", start: rest.start, end: rest.end,
                              locationName: rest.locationName,
                              memo: "次の予定に備えて、無理のない範囲で休憩しましょう。",
                              mode: .suggested)
                }
            }
            Label {
                message
            } icon: {
                Image(systemName: "info.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var message: some View {
        switch gap {
        case .planned(let plan):
            switch plan.notice {
            case .insufficientPreparation:
                Text("開始には間に合う見込みですが、到着後10分の余裕はありません。")
            case .preparationReserved:
                Text("次の予定の前に10分の準備時間を確保しています。")
            }
        case .unavailable(let failure):
            switch failure {
            case .overlappingEvents:
                Text("予定の時間が重なっているため、この区間には提案を追加できません。")
            case .missingLocation:
                Text("移動時間を調べるには、両方の予定の場所を検索結果から設定してください。")
            case .invalidTravelTime:
                Text("有効な移動時間を取得できませんでした。")
            case .routeUnavailable:
                Text("車の移動時間を取得できませんでした。通信環境や場所を確認し、再試行してください。")
            case .arrivalTooLate(let minutes):
                Text("移動に約\(minutes, format: .number.precision(.fractionLength(0)))分必要なため、次の予定に間に合いません。予定の時間を見直してください。")
            case .unexpectedFailure:
                Text("提案を作成できませんでした。もう一度お試しください。")
            }
        }
    }
}
