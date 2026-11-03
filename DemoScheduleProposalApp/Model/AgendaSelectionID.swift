//
//  AgendaSelectionID.swift
//  DemoScheduleProposalApp
//

//
//  予定と現在時刻の起点を区別するための識別子を定義する。

import SwiftData

enum AgendaSelectionID: Hashable {
    case now
    case event(PersistentIdentifier)
}
