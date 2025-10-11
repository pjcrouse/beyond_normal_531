import SwiftUI

struct ImplementsEditorView: View {
    @ObservedObject private var impl = ImplementWeights.shared
    @State private var q: String = ""

    // Inline editing state
    @State private var editingID: String?
    @State private var editingText: String = ""
    @FocusState private var editingFocused: Bool

    // Constraints / options
    private let minW = 1.0
    private let maxW = 200.0
    private let isDecimalAllowed = false // set true if you want 2.5 etc.

    // Which implements are editable
    private var items: [(id: String, name: String)] {
        let mains: [(String, String)] = [
            ("SQ", "Squat (Main)"),
            ("BP", "Bench (Main)"),
            ("DL", "Deadlift (Main)"),
            ("RW", "Row (Main)")
        ]
        let bars = AssistanceExercise.catalog
            .filter { ["front_squat", "paused_squat", "close_grip", "triceps_ext"].contains($0.id) }
            .map { ($0.id, $0.name) }
        return (mains + bars)
            .filter { q.isEmpty || $0.1.localizedCaseInsensitiveContains(q) }
            .sorted { $0.1 < $1.1 }
    }

    var body: some View {
        List {
            Section(footer: Text("Changes save automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)) {
                ForEach(items, id: \.id) { item in
                    let id = item.id
                    let current = impl.weight(for: id)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.name)
                            Spacer()

                            if editingID == id {
                                // Inline numeric field (fixed width so it never collapses to 0)
                                TextField("", text: $editingText)
                                    .keyboardType(isDecimalAllowed ? .decimalPad : .numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 96)
                                    .monospacedDigit()
                                    .focused($editingFocused)
                                    .submitLabel(.done)
                                    .onSubmit { commitInlineEdit(for: id) }
                                    .onChange(of: editingText) { _, t in
                                        let filtered = filteredNumericString(t, allowDecimal: isDecimalAllowed)
                                        if filtered != t { editingText = filtered }
                                    }
                            } else {
                                // Current value (tap to edit)
                                Button {
                                    editingText = displayString(for: current, decimals: isDecimalAllowed)
                                    editingID = id
                                } label: {
                                    Text("\(displayString(for: current, decimals: isDecimalAllowed)) lb")
                                        .font(.callout)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(item.name) weight, \(Int(current)) pounds, tap to edit")
                            }
                        }

                        // Stepper for small nudges
                        Stepper(value: Binding(
                            get: { Int(impl.weight(for: id)) },
                            set: { impl.setWeight(clamp(Double($0)), for: id) }
                        ), in: Int(minW)...Int(maxW)) {
                            Text("Adjust")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Per-row reset
                        if Int(current) != Int(defaultFor(id)) {
                            Button {
                                impl.setWeight(defaultFor(id), for: id)
                            } label: {
                                Label("Reset to default (\(Int(defaultFor(id))) lb)", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button {
                    impl.restoreDefaults()
                } label: {
                    Label("Restore All Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Implements")
        .searchable(text: $q)
        .onChange(of: editingID) { _, newID in
            if newID != nil {
                DispatchQueue.main.async { editingFocused = true }
            } else {
                editingFocused = false
            }
        }
        .safeAreaInset(edge: .bottom) {
            if editingFocused {
                HStack {
                    Spacer()
                    Button {
                        if let id = editingID { commitInlineEdit(for: id) }
                        resignKeyboard()
                    } label: {
                        Label("Done", systemImage: "keyboard.chevron.compact.down")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: editingFocused)
    }

    // MARK: - Helpers

    private func commitInlineEdit(for id: String) {
        let v = parsedNumber(from: editingText, allowDecimal: isDecimalAllowed)
        let clamped = clamp(v ?? impl.weight(for: id))
        impl.setWeight(clamped, for: id)
        editingID = nil
        editingText = ""
    }

    private func clamp(_ x: Double) -> Double { max(minW, min(x, maxW)) }

    private func displayString(for x: Double, decimals: Bool) -> String {
        decimals
            ? String(format: x.rounded() == x ? "%.0f" : "%.1f", x)
            : String(format: "%.0f", x)
    }

    private func filteredNumericString(_ s: String, allowDecimal: Bool) -> String {
        if allowDecimal {
            var seenDot = false
            return s.filter { c in
                if c.isNumber { return true }
                if c == "." && !seenDot { seenDot = true; return true }
                return false
            }
        } else {
            return s.filter(\.isNumber)
        }
    }

    private func parsedNumber(from s: String, allowDecimal: Bool) -> Double? {
        allowDecimal ? Double(s) : Double(Int(s) ?? 0)
    }

    private func defaultFor(_ id: String) -> Double {
        let defaults: [String: Double] = [
            "SQ": 75, "BP": 45, "DL": 45, "RW": 45,
            "front_squat": 45, "paused_squat": 45, "close_grip": 45, "triceps_ext": 25
        ]
        return defaults[id] ?? 45
    }

    private func resignKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
