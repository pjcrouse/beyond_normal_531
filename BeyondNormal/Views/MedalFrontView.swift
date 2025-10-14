import SwiftUI

struct MedalFrontView: View {
    var body: some View {
        Image("deadlift_medal_front")   // must match your Assets name
            .resizable()
            .scaledToFit()
            .background(Color.black)
    }
}
