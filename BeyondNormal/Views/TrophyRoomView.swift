import SwiftUI

// Drives the share sheet with a captured payload (prevents state timing issues)
struct ShareRequest: Identifiable {
    let id = UUID()
    let context: ShareContentType
}

struct TrophyRoomView: View {
    @StateObject private var store = AwardStore()

    @State private var selectedLift: LiftType? = nil
    @State private var sortOption: SortOption = .dateDescending

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // MARK: Filter + Sort Controls
                HStack(spacing: 12) {
                    // Lift filter
                    Menu {
                        Button("All Lifts") { selectedLift = nil }
                        Divider()
                        ForEach(LiftType.allCases, id: \.self) { lift in
                            Button(lift.rawValue.capitalized) {
                                selectedLift = lift
                            }
                        }
                    } label: {
                        Label(selectedLift?.rawValue.capitalized ?? "All Lifts",
                              systemImage: "line.3.horizontal.decrease.circle")
                        .font(.callout)
                    }

                    // Sort control
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.label) { sortOption = option }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                            .font(.callout)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAndSortedAwards) { award in
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
            }
            .navigationTitle("Trophy Room")
        }
    }

    // MARK: - Filter + Sort Logic

    private var filteredAndSortedAwards: [Award] {
        var result = store.awards

        // Filter by lift type
        if let lift = selectedLift {
            result = result.filter { $0.lift == lift }
        }

        // Sort
        switch sortOption {
        case .dateAscending:
            result.sort { $0.date < $1.date }
        case .dateDescending:
            result.sort { $0.date > $1.date }
        case .weightAscending:
            result.sort { extractWeight(from: $0.title) < extractWeight(from: $1.title) }
        case .weightDescending:
            result.sort { extractWeight(from: $0.title) > extractWeight(from: $1.title) }
        }

        return result
    }

    // Extract numeric weight from a title like "500 LB DEADLIFT PR"
    private func extractWeight(from title: String) -> Int {
        let components = title.split(separator: " ")
        if let first = components.first, let value = Int(first) {
            return value
        }
        return 0
    }
}

// MARK: - Sort Options
enum SortOption: CaseIterable {
    case dateAscending, dateDescending, weightAscending, weightDescending

    var label: String {
        switch self {
        case .dateAscending: return "Date (Oldest → Newest)"
        case .dateDescending: return "Date (Newest → Oldest)"
        case .weightAscending: return "Weight (Lightest → Heaviest)"
        case .weightDescending: return "Weight (Heaviest → Lightest)"
        }
    }
}

struct AwardDetailView: View {
    let award: Award

    // Item-driven sheet (more reliable than Bool + separate text/image state)
    @State private var activeShare: ShareRequest?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Medal3DView(award: award)
                    .frame(maxWidth: 420, maxHeight: 420)
                    .padding(.top, 20)

                Text(award.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(award.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    // Build the share request with the context
                    activeShare = ShareRequest(context: .award(award))
                } label: {
                    Label("Share Award", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .sheet(item: $activeShare) { req in
            ShareSheet(context: req.context)
        }
    }
}

struct AwardImage: View {
    let award: Award
    var front: Bool

    var body: some View {
        if let img = AwardGenerator.shared.resolveImage(front ? award.frontImagePath : award.backImagePath) {
            img.resizable()
                .interpolation(.high)   // sharper thumbnails
                .antialiased(true)
                .scaledToFit()
        } else {
            Color.gray
        }
    }
}
