import SwiftUI

struct ExercisePickerView: View {
    let title: String
    @Binding var selectedID: String
    let allowedCategories: [ExerciseCategory]

    @State private var query: String = ""

    private var filtered: [AssistanceExercise] {
        AssistanceExercise.catalog
            .filter { allowedCategories.contains($0.category) }
            .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No matches",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term.")
                )
            } else {
                ForEach(filtered) { ex in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name).font(.body)
                            Text(ex.category.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedID == ex.id {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedID = ex.id }
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $query, placement: .navigationBarDrawer)
    }
}
