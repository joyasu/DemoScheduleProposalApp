import Foundation

struct ProposalRequest: Identifiable {
    let id = UUID()
    let intervals: [ProposalInterval]
}
