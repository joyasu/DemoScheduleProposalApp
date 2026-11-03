import Foundation

struct ScheduleTravel: Identifiable, Equatable {
    let id: UUID
    var originName: String
    var destinationName: String
    var departure: Date
    var arrival: Date
    var memo: String

    var duration: TimeInterval { max(0, arrival.timeIntervalSince(departure)) }

    init(id: UUID = UUID(), originName: String, destinationName: String,
         departure: Date, arrival: Date, memo: String = "") {
        self.id = id
        self.originName = originName
        self.destinationName = destinationName
        self.departure = departure
        self.arrival = arrival
        self.memo = memo
    }
}
