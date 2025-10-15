import SwiftUI

struct MedalFrontView: View {
    var body: some View {
        Image("deadlift_medal_front")
            .resizable()
            .scaledToFit()
            .clipShape(Circle())      // <- trims the square to a circular alpha
            .background(Color.clear)  // <- do not paint black
    }
}
