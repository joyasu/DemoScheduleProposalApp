import Foundation

struct EventLocation: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
}
