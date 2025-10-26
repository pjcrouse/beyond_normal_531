import SwiftUI

struct WorkoutNotesBlock: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding   // <-- new

    init(text: Binding<String>, isFocused: FocusState<Bool>.Binding) {
        _text = text
        self.isFocused = isFocused
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Notes")
                .font(.headline)

            TextEditor(text: $text)
                .focused(isFocused)
                .onTapGesture {                      // 👈 add this here
                    isFocused.wrappedValue = true
                }// <-- wire focus
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)   // (nice on iOS 16+)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal)
    }
}
