import Foundation

enum ProposalGap: Equatable {
    enum Failure: Equatable {
        case overlappingEvents
        case missingLocation
        case invalidTravelTime
        case routeUnavailable
        case arrivalTooLate(requiredMinutes: Double)
        case unexpectedFailure
    }

    enum Notice: Equatable {
        case insufficientPreparation
        case preparationReserved
    }

    struct Rest: Equatable {
        let start: Date
        let end: Date
        let locationName: String?

        init?(start: Date, end: Date, locationName: String?) {
            guard end >= start else { return nil }
            self.start = start
            self.end = end
            self.locationName = locationName
        }
    }

    struct Plan: Equatable {
        let travel: ScheduleTravel
        let rest: Rest?
        let notice: Notice
    }

    case planned(Plan)
    case unavailable(Failure)

    var plan: Plan? {
        guard case .planned(let plan) = self else { return nil }
        return plan
    }

    static func planned(from: ProposalEvent, to: ProposalEvent, duration: TimeInterval) -> ProposalGap {
        guard duration.isFinite, duration >= 0 else { return .unavailable(.invalidTravelTime) }
        guard from.end <= to.start else { return .unavailable(.overlappingEvents) }
        let arrival = from.end.addingTimeInterval(duration)
        let preparationDuration: TimeInterval = 600
        let minimumRestDuration: TimeInterval = 300
        let restEnd = to.start.addingTimeInterval(-preparationDuration)
        guard arrival <= to.start else {
            return .unavailable(.arrivalTooLate(requiredMinutes: ceil(duration / 60)))
        }
        let travel = ScheduleTravel(
            originName: from.location?.name ?? from.title,
            destinationName: to.location?.name ?? to.title,
            departure: from.end, arrival: arrival
        )
        let rest = restEnd.timeIntervalSince(arrival) >= minimumRestDuration
            ? Rest(start: arrival, end: restEnd, locationName: to.location?.name) : nil
        return .planned(Plan(
            travel: travel, rest: rest,
            notice: arrival > restEnd ? .insufficientPreparation : .preparationReserved
        ))
    }
}
