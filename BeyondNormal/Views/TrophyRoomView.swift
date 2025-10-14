import SwiftUI

struct TrophyRoomView: View {
    @StateObject private var store = AwardStore()

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.awards) { award in
                        NavigationLink {
                            AwardDetailView(award: award)
                        } label: {
                            VStack(spacing: 8) {
                                AwardImage(award: award, front: true)
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                Text(award.title)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                Text(award.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Trophy Room")
        }
    }
}

struct AwardImage: View {
    let award: Award
    var front: Bool
    var body: some View {
        if let img = AwardGenerator.shared.resolveImage(front ? award.frontImagePath : award.backImagePath) {
            img.resizable().scaledToFit()
        } else {
            Color.gray
        }
    }
}

struct AwardDetailView: View {
    let award: Award
    @State private var flipped = false

    var body: some View {
        ZStack {
            AwardImage(award: award, front: true)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            AwardImage(award: award, front: false)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .background(Color.black.ignoresSafeArea())
        .frame(maxWidth: 500, maxHeight: 500)
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { flipped.toggle() }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(award.title).font(.headline)
                    Text(award.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
