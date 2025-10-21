import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var settings: ProgramSettings
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    // Temp strings for numeric TextFields (to avoid fighting the keyboard)
    @State private var tmpSquat = ""
    @State private var tmpBench = ""
    @State private var tmpDeadlift = ""
    @State private var tmpRow = ""
    @State private var tmpPress = ""
    @State private var tmpBarWeight = ""
    @State private var tmpRoundTo = ""
    @State private var tmpTimerRegular = ""
    @State private var tmpTimerBBB = ""

    enum Field {
        case squat, bench, deadlift, row, press, barWeight, roundTo, timerRegular, timerBBB
    }

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                trainingMaxesSection
                workoutsPerWeekSection
                loadingSection
                bbbSection
                restTimerSection
                oneRMSection
                tmProgressionSection
                assistanceSection
                implementsSection
                behaviorSection
                resetDefaultsSection
                prsSection
                helpSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAndClose()
                        settings.save()
                    }.bold()
                }
                if focusedField != nil {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
            }
            .onAppear(perform: onAppearSetup)
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Display Name")
                Spacer()
                TextField("Your name", text: $settings.userDisplayName)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
            Text("Your name appears on PR award medals. Leave blank to use default.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var trainingMaxesSection: some View {
        Section("Training Maxes (lb)") {
            numField("Squat", value: $tmpSquat, field: .squat)
            numField("Bench", value: $tmpBench, field: .bench)
            numField("Deadlift", value: $tmpDeadlift, field: .deadlift)
            numField("Row", value: $tmpRow, field: .row)
            numField("Press", value: $tmpPress, field: .press)
        }
    }

    private var workoutsPerWeekSection: some View {
        Section("Workouts per Week") {
            Picker("Count", selection: $settings.workoutsPerWeek) {
                Text("3 days").tag(3)
                Text("4 days").tag(4)
                Text("5 days").tag(5)
            }
            .pickerStyle(.segmented)

            if settings.workoutsPerWeek == 4 {
                Picker("4th Workout", selection: $settings.fourthLiftRaw) {
                    Text("Row").tag("row")
                    Text("Press").tag("press")
                }
                .pickerStyle(.segmented)

                Text("If 4 days: choose Row or Standing Press for Day 4.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if settings.workoutsPerWeek == 5 {
                Text("5 days include both Row and Standing Press.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("3 days: Squat, Bench, Deadlift.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var loadingSection: some View {
        Section("Loading") {
            numField("Default Bar Weight (lb)", value: $tmpBarWeight, field: .barWeight)
            numField("Round To (lb)", value: $tmpRoundTo, field: .roundTo)
            Text("Tip: Per-exercise implements override the default for plate math.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var bbbSection: some View {
        Section("Assistance (BBB)") {
            HStack {
                Text("BBB % of TM")
                Spacer()
                Text("\(Int(settings.bbbPercent * 100))%").foregroundStyle(.secondary)
            }
            Slider(value: $settings.bbbPercent, in: 0.50...0.70, step: 0.05)
        }
    }

    private var restTimerSection: some View {
        Section("Rest Timer (seconds)") {
            HStack {
                Text("Regular sets")
                Spacer()
                TextField("180", text: $tmpTimerRegular)
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
                TextField("120", text: $tmpTimerBBB)
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
    }

    private var oneRMSection: some View {
        Section(header: Text("1RM Formula")) {
            Picker("Estimation Formula", selection: $settings.oneRMFormula) {
                ForEach(OneRepMaxFormula.allCases, id: \.self) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .pickerStyle(.segmented)

            Text("Epley = simple/standard • Brzycki = conservative at high reps • Mayhew = research-based sigmoid")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var tmProgressionSection: some View {
        Section("TM Progression Style") {
            Picker("Style", selection: $settings.progressionStyle) {
                Text("Classic (+5/+10)").tag(ProgressionStyle.classic)
                Text("Auto (from PRs)").tag(ProgressionStyle.auto)
            }
            .pickerStyle(.segmented)

            if settings.progressionStyle == .auto {
                Stepper(value: $settings.autoTMPercent, in: 80...95, step: 1) {
                    Text("TM = \(settings.autoTMPercent)% of est-1RM")
                }
                Text("Classic = steady +5 upper / +10 lower per cycle.\nAuto = set TM to a % of latest AMRAP est. 1RM (capped).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Classic = steady +5 upper / +10 lower per cycle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var assistanceSection: some View {
        Section("Assistance Exercises") {
            NavigationLink("Squat Day") {
                ExercisePickerView(
                    title: "Choose Squat Assistance",
                    selectedID: $settings.assistSquatID,
                    allowedCategories: [.legs],
                    lift: .squat
                )
            }
            NavigationLink("Bench Day") {
                ExercisePickerView(
                    title: "Choose Bench Assistance",
                    selectedID: $settings.assistBenchID,
                    allowedCategories: [.push],
                    lift: .bench
                )
            }
            NavigationLink("Deadlift Day") {
                ExercisePickerView(
                    title: "Choose Deadlift Assistance",
                    selectedID: $settings.assistDeadliftID,
                    allowedCategories: Lift.deadlift.categoriesForPicker,
                    lift: .deadlift
                )
            }

            if settings.workoutsPerWeek == 4 {
                if settings.fourthLiftRaw == "row" {
                    rowPickerLink
                } else {
                    pressPickerLink
                }
            } else if settings.workoutsPerWeek >= 5 {
                rowPickerLink
                pressPickerLink
            }

            Button {
                // Restore recommended defaults
                settings.assistSquatID   = "split_squat"
                settings.assistBenchID   = "triceps_ext"
                settings.assistDeadliftID = "back_ext"
                settings.assistRowID     = "spider_curls"
                settings.assistPressID   = "triceps_ext"
            } label: {
                Label("Restore Recommended", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var rowPickerLink: some View {
        NavigationLink("Row Day") {
            ExercisePickerView(
                title: "Choose Row Assistance",
                selectedID: $settings.assistRowID,
                allowedCategories: [.pull],
                lift: .row
            )
        }
    }

    private var pressPickerLink: some View {
        NavigationLink("Press Day") {
            ExercisePickerView(
                title: "Choose Press Assistance",
                selectedID: $settings.assistPressID,
                allowedCategories: [.push],
                lift: .press
            )
        }
    }

    private var implementsSection: some View {
        Section("Implements") {
            NavigationLink("Configure Implements") {
                ImplementsEditorView()
            }
            Text("Set per-exercise bar/EZ implement weights for plate math.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Auto-advance week after finishing workout", isOn: $settings.autoAdvanceWeek)
        }
    }

    private var resetDefaultsSection: some View {
        Section {
            Button(role: .destructive) {
                tmpSquat = "315"; tmpBench = "225"
                tmpDeadlift = "405"; tmpRow = "185"; tmpPress = "135"
                tmpBarWeight = "45"; tmpRoundTo = "5"
                tmpTimerRegular = "180"; tmpTimerBBB = "120"
                ImplementWeights.shared.restoreDefaults()
            } label: {
                Label("Reset to defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var prsSection: some View {
        Section("Personal Records") {
            Button(role: .destructive) {
                PRStore.shared.resetCycle(settings.currentCycle)
            } label: {
                Label("Reset Current Cycle PRs", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var helpSection: some View {
        Section("Help & Support") {
            NavigationLink("User Guide 📖") {
                UserGuideView()
            }
            Link("Send Feedback Email", destination: URL(string: "mailto:support@beyondnormal.app")!)
        }
    }

    // MARK: - Helpers

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

    private func onAppearSetup() {
        // Seed temp fields from settings
        tmpSquat = String(format: "%.0f", settings.tmSquat)
        tmpBench = String(format: "%.0f", settings.tmBench)
        tmpDeadlift = String(format: "%.0f", settings.tmDeadlift)
        tmpRow = String(format: "%.0f", settings.tmRow)
        tmpPress = String(format: "%.0f", settings.tmPress)
        tmpBarWeight = String(format: "%.0f", settings.barWeight)
        tmpRoundTo = String(format: "%.0f", settings.roundTo)
        tmpTimerRegular = String(settings.timerRegularSec)
        tmpTimerBBB = String(settings.timerBBBSec)

        // Sanitize options
        if settings.fourthLiftRaw != "row" && settings.fourthLiftRaw != "press" {
            settings.fourthLiftRaw = "row"
        }
        if !(3...5).contains(settings.workoutsPerWeek) {
            settings.workoutsPerWeek = 4
        }
    }

    private func saveAndClose() {
        if let v = Double(tmpSquat)      { settings.tmSquat = v }
        if let v = Double(tmpBench)      { settings.tmBench = v }
        if let v = Double(tmpDeadlift)   { settings.tmDeadlift = v }
        if let v = Double(tmpRow)        { settings.tmRow = v }
        if let v = Double(tmpPress)      { settings.tmPress = v }
        if let v = Double(tmpBarWeight)  { settings.barWeight = max(1, min(v, 200)) }
        if let v = Double(tmpRoundTo)    { settings.roundTo   = max(0.5, min(v, 100)) }
        if let v = Int(tmpTimerRegular)  { settings.timerRegularSec = max(1, v) }
        if let v = Int(tmpTimerBBB)      { settings.timerBBBSec     = max(1, v) }
        dismiss()
    }
}
