import SwiftUI

struct AgendaDayFrames: PreferenceKey {
    static var defaultValue: [Date: CGRect] { [:] }

    static func reduce(value: inout [Date: CGRect], nextValue: () -> [Date: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $0.union($1) })
    }
}

extension View {
    func agendaDayFrame(_ date: Date) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: AgendaDayFrames.self,
                                       value: [date: geometry.frame(in: .named("agendaList"))])
            }
        }
    }
}
