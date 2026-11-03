import SwiftUI

struct EventLocationSection: View {
    @Binding var location: EventLocation?
    let chooseLocation: () -> Void

    var body: some View {
        Section("場所") {
            if let location {
                Label(location.name, systemImage: "mappin.and.ellipse")
                if let address = location.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("場所を変更", action: chooseLocation)
                Button("場所を解除", role: .destructive) {
                    self.location = nil
                }
            } else {
                Button("場所を追加", systemImage: "mappin.and.ellipse", action: chooseLocation)
            }
        }
    }
}
