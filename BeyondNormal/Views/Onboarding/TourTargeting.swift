import SwiftUI

struct TourTargetsPreferenceKey: PreferenceKey {
    static var defaultValue: [TourTargetID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourTargetID: Anchor<CGRect>],
                       nextValue: () -> [TourTargetID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct TourTarget: ViewModifier {
    let id: TourTargetID
    func body(content: Content) -> some View {
        content.anchorPreference(key: TourTargetsPreferenceKey.self, value: .bounds) { [id: $0] }
    }
}

extension View {
    func tourTarget(id: TourTargetID) -> some View { modifier(TourTarget(id: id)) }
}
