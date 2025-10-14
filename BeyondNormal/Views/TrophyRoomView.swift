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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // 👇 This is the new interactive medal
                InteractiveMedalFlipView(award: award)
                    .frame(width: 300, height: 300)
                    .padding(.top, 40)

                Text(award.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(award.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
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
