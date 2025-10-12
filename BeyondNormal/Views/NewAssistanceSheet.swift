import SwiftUI

struct NewAssistanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: AssistanceLibrary
    let preselectedCategory: ExerciseCategory?   // pass from caller when you know it

    // explicit init so Swift is happy with @ObservedObject + defaulted arg
    init(library: AssistanceLibrary, preselectedCategory: ExerciseCategory? = nil) {
        self._library = ObservedObject(wrappedValue: library)
        self.preselectedCategory = preselectedCategory
    }

    // form fields (minimal)
    @State private var name = ""
    @State private var category: ExerciseCategory = .core
    @State private var defaultWeight: Double = 0       // 0 = bodyweight / machine stack TBD
    @State private var defaultReps: Int = 10

    @AppStorage("creatorDisplayName") private var authorName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Creator") {
                    TextField("Your name (optional)", text: $authorName)
                        .textInputAutocapitalization(.words)
                }

                Section("Exercise Info") {
                    TextField("Name (e.g. Reverse Hyper)", text: $name)
                        .textInputAutocapitalization(.words)

                    if let _ = preselectedCategory {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(category.rawValue.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(ExerciseCategory.allCases, id: \.self) {
                                Text($0.rawValue.capitalized)
                            }
                        }
                    }

                    Stepper("Default Reps: \(defaultReps)", value: $defaultReps, in: 1...30)
                    Stepper("Default Weight: \(Int(defaultWeight)) lb",
                            value: $defaultWeight, in: 0...500, step: 5)
                }
            }
            .onAppear {
                if let c = preselectedCategory { category = c }
            }
            .navigationTitle("New Assistance Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveAndClose() {
        // We keep areas/tags empty for now; model stays forward-compatible.
        // Toggle fields are set to safe defaults; UI always allows manual edits during the workout anyway.
        library.add(name: name,
                    defaultWeight: defaultWeight,
                    defaultReps: defaultReps,
                    allowWeightToggle: false,
                    toggledWeight: 0,
                    usesImpliedImplements: (defaultWeight == 0),
                    category: category,
                    areas: [],
                    tags: [],
                    authorDisplayName: authorName.isEmpty ? nil : authorName)
        dismiss()
    }
}
