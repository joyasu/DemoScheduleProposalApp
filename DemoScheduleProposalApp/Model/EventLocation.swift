//
//  EventLocation.swift
//  DemoScheduleProposalApp
//

//
//  場所の名称、住所、緯度・経度と識別子を保持する。

import Foundation

struct EventLocation: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
}
