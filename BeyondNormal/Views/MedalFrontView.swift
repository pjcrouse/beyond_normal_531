import SwiftUI

struct MedalFrontView: View {
    let lift: LiftType
    var body: some View {
        Image(lift.frontImageAssetName)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())      // <- trims the square to a circular alpha
            .background(Color.clear)  // <- do not paint black
    }
}
