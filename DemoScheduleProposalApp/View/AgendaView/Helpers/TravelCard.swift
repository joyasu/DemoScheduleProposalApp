import SwiftUI

struct TravelCard: View {
    let travel: ScheduleTravel
    var mode: CardDisplayMode = .standard

    var body: some View {
        ScheduleCardFrame(title: "移動", symbol: "car.fill", mode: mode) {
            VStack(alignment: .leading, spacing: 8) {
                Text("車で移動")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Label("出発：\(travel.originName)", systemImage: "circle")
                Label("到着：\(travel.destinationName)", systemImage: "mappin")
                EventTimeLabel(start: travel.departure, end: travel.arrival, isAllDay: false)
                Text("所要時間：約\(Int(ceil(travel.duration / 60)))分")
                if !travel.memo.isEmpty {
                    Text(travel.memo)
                        .lineLimit(2)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("カード4種類") {
    let start = Date.now
    let end = start.addingTimeInterval(1800)
    let travel = ScheduleTravel(
        originName: "自宅", destinationName: "打ち合わせ先",
        departure: start, arrival: end
    )
    ScrollView {
        VStack(spacing: 12) {
            EventCard(title: "打ち合わせ", start: start, end: end, locationName: "オフィス")
            EventCard(title: "カフェで休憩", start: start, end: end,
                      locationName: "駅前のカフェ", mode: .suggested)
            TravelCard(travel: travel)
            TravelCard(travel: travel, mode: .suggested)
        }
        .padding()
    }
}
