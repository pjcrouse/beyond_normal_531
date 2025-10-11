import SwiftUI

struct NotesField: View {
    @Binding var text: String
    @FocusState var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workout Notes").font(.headline)
                Spacer()
                Text("saved with history").font(.caption).foregroundStyle(.secondary)
            }
            TextField("Add notes about today's workout...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .autocorrectionDisabled()
                .focused($focused)
        }
    }
}
