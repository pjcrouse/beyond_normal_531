import SwiftUI

struct SettingsSheet: View {
    @Binding var tmSquat: Double
    @Binding var tmBench: Double
    @Binding var tmDeadlift: Double
    @Binding var tmRow: Double
    @Binding var barWeight: Double
    @Binding var roundTo: Double
    @Binding var bbbPct: Double
    @Binding var timerRegularSec: Int
    @Binding var timerBBBsec: Int
    @Binding var tmProgStyleRaw: String
    @Binding var autoAdvanceWeek: Bool
    @Binding var oneRMFormulaRaw: String

    // Assistance exercise selections
    @Binding var assistSquatID: String
    @Binding var assistBenchID: String
    @Binding var assistDeadliftID: String
    @Binding var assistRowID: String

    @State private var tmpSquat = ""
    @State private var tmpBench = ""
    @State private var tmpDeadlift = ""
    @State private var tmpRow = ""
    @State private var tmpBarWeight = ""
    @State private var tmpRoundTo = ""
    @State private var tmpTimerRegular = ""
    @State private var tmpTimerBBB = ""

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case squat, bench, deadlift, row, barWeight, roundTo, timerRegular, timerBBB
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Training Maxes (lb)") {
                    numField("Squat", value: $tmpSquat, field: .squat)
                    numField("Bench", value: $tmpBench, field: .bench)
                    numField("Deadlift", value: $tmpDeadlift, field: .deadlift)
                    numField("Row", value: $tmpRow, field: .row)
                }

                Section("Loading") {
                    numField("Default Bar Weight (lb)", value: $tmpBarWeight, field: .barWeight)
                    numField("Round To (lb)", value: $tmpRoundTo, field: .roundTo)
                    Text("Tip: Per-exercise implements override the default for plate math.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Assistance (BBB)") {
                    HStack {
                        Text("BBB % of TM")
                        Spacer()
                        Text("\(Int(bbbPct * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $bbbPct, in: 0.50...0.70, step: 0.05)
                }

                Section("Rest Timer (seconds)") {
                    HStack {
                        Text("Regular sets")
                        Spacer()
                        TextField("240", text: $tmpTimerRegular)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .timerRegular)
                    }
                    HStack {
                        Text("BBB / accessory")
                        Spacer()
                        TextField("180", text: $tmpTimerBBB)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .timerBBB)
                    }
                    Text("Tip: 240s = 4:00, 180s = 3:00")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("1RM Formula")) {
                    Picker("Estimation Formula", selection: $oneRMFormulaRaw) {
                        Text("Epley").tag("epley")
                        Text("Wendler").tag("wendler")
                    }
                    .pickerStyle(.segmented)
                }

                Section("TM Progression Style") {
                    Picker("Style", selection: $tmProgStyleRaw) {
                        Text("Classic (+5/+10)").tag("classic")
                        Text("Auto (90% of AMRAP 1RM)").tag("auto")
                    }
                    .pickerStyle(.segmented)
                    Text("Classic = steady +5 upper / +10 lower per cycle.\nAuto = set TM to 90% of latest AMRAP est. 1RM (capped at +10 upper / +20 lower).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Assistance Exercises") {
                    NavigationLink("Squat Day") {
                        ExercisePickerView(
                            title: "Choose Squat Assistance",
                            selectedID: $assistSquatID,
                            allowedCategories: [.legs]
                        )
                    }
                    NavigationLink("Bench Day") {
                        ExercisePickerView(
                            title: "Choose Bench Assistance",
                            selectedID: $assistBenchID,
                            allowedCategories: [.push]
                        )
                    }
                    NavigationLink("Deadlift Day") {
                        ExercisePickerView(
                            title: "Choose Deadlift Assistance",
                            selectedID: $assistDeadliftID,
                            allowedCategories: [.legs, .core]
                        )
                    }
                    NavigationLink("Row Day") {
                        ExercisePickerView(
                            title: "Choose Row Assistance",
                            selectedID: $assistRowID,
                            allowedCategories: [.pull]
                        )
                    }

                    Button {
                        // Restore recommended defaults
                        assistSquatID = "split_squat"
                        assistBenchID = "triceps_ext"
                        assistDeadliftID = "back_ext"
                        assistRowID = "spider_curls"
                    } label: {
                        Label("Restore Recommended", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("Implements") {
                    NavigationLink("Configure Implements") {
                        ImplementsEditorView()
                    }
                    Text("Set per-exercise bar/EZ implement weights for plate math.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Behavior") {
                    Toggle("Auto-advance week after finishing workout", isOn: $autoAdvanceWeek)
                }

                Section {
                    Button(role: .destructive) {
                        tmpSquat = "315"; tmpBench = "225"
                        tmpDeadlift = "405"; tmpRow = "185"
                        tmpBarWeight = "45"; tmpRoundTo = "5"
                        tmpTimerRegular = "240"; tmpTimerBBB = "180"
                        ImplementWeights.shared.restoreDefaults()
                    } label: {
                        Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                    }
                }
                Section("Help & Support") {
                    NavigationLink("User Guide 📖") {
                        UserGuideView()
                    }
                    Link("Send Feedback Email", destination: URL(string: "mailto:support@beyondnormal.app")!)
                }
            }
            .toolbar {
                if focusedField != nil {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let v = Double(tmpSquat) { tmSquat = v }
                        if let v = Double(tmpBench) { tmBench = v }
                        if let v = Double(tmpDeadlift) { tmDeadlift = v }
                        if let v = Double(tmpRow) { tmRow = v }
                        if let v = Double(tmpBarWeight) { barWeight = max(1, min(v, 200)) }
                        if let v = Double(tmpRoundTo) { roundTo   = max(0.5, min(v, 100)) }
                        if let v = Int(tmpTimerRegular) { timerRegularSec = max(1, v) }
                        if let v = Int(tmpTimerBBB) { timerBBBsec     = max(1, v) }
                        dismiss()
                    }.bold()
                }
            }
            .onAppear {
                tmpSquat = String(format: "%.0f", tmSquat)
                tmpBench = String(format: "%.0f", tmBench)
                tmpDeadlift = String(format: "%.0f", tmDeadlift)
                tmpRow = String(format: "%.0f", tmRow)
                tmpBarWeight = String(format: "%.0f", barWeight)
                tmpRoundTo = String(format: "%.0f", roundTo)
                tmpTimerRegular = String(timerRegularSec)
                tmpTimerBBB = String(timerBBBsec)
            }
        }
    }

    @ViewBuilder
    private func numField(_ label: String, value: Binding<String>, field: Field) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .focused($focusedField, equals: field)
        }
    }
}
