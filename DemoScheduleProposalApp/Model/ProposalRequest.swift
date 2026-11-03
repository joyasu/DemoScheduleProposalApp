//
//  ProposalRequest.swift
//  DemoScheduleProposalApp
//

//
//  提案対象として選択した空き区間とリクエストの識別子を保持する。

import Foundation

struct ProposalRequest: Identifiable {
    let id = UUID()
    let intervals: [ProposalInterval]
}
