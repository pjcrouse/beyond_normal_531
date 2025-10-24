import SwiftUI

// MARK: - Rows

public struct SetRow: View {
    public let label: String
    public let weight: Double
    public let perSide: [Double]
    @Binding public var done: Bool
    public var onCheck: ((Bool) -> Void)?
    public let refreshID: String

    @State private var lastKnownDone: Bool = false

    public init(label: String, weight: Double, perSide: [Double], done: Binding<Bool>,
                onCheck: ((Bool) -> Void)? = nil, refreshID: String = "") {
        self.label = label
        self.weight = weight
        self.perSide = perSide
        self._done = done
        self.onCheck = onCheck
        self.refreshID = refreshID
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Toggle(isOn: $done) { Text(label) }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(weight)) lb").font(.headline)
                if !perSide.isEmpty {
                    Text("Per side: " + LoadFormat.plateList(perSide))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: done) { old, new in
            guard lastKnownDone == old else {
                lastKnownDone = new
                return
            }

            if !old && new {
                onCheck?(true)
            }
            lastKnownDone = new
        }
        .onAppear {
            lastKnownDone = done
        }
        .task(id: refreshID) {
            lastKnownDone = done
        }
    }
}

public struct AMRAPRow: View {
    public let label: String
    public let weight: Double
    public let perSide: [Double]
    @Binding public var done: Bool
    @Binding public var reps: String
    public let est1RM: Double
    public let capNote: String?
    public var onCheck: ((Bool) -> Void)?
    public var focus: FocusState<Bool>.Binding
    public let refreshID: String
    
    // ✅ NEW: carry the chosen formula down to the row
    public let currentFormula: OneRepMaxFormula
    
    public let liftLabel: String
    public let currentCycle: Int

    @State private var lastKnownDone: Bool = false

    public init(label: String, weight: Double, perSide: [Double], done: Binding<Bool>, reps: Binding<String>, est1RM: Double, capNote: String? = nil, onCheck: ((Bool) -> Void)? = nil, focus: FocusState<Bool>.Binding, refreshID: String = "", currentFormula: OneRepMaxFormula,liftLabel: String, currentCycle: Int) {
        self.label = label
        self.weight = weight
        self.perSide = perSide
        self._done = done
        self._reps = reps
        self.est1RM = est1RM
        self.capNote = capNote
        self.onCheck = onCheck
        self.focus = focus
        self.refreshID = refreshID
        self.currentFormula = currentFormula
        self.liftLabel = liftLabel
        self.currentCycle = currentCycle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $done) { Text(label).font(.headline) }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(weight)) lb").font(.headline)
                    if !perSide.isEmpty {
                        Text("Per side: " + LoadFormat.plateList(perSide))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Text("AMRAP reps:")
                TextField("e.g. 8", text: $reps)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .focused(focus)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .id("amrap-\(liftLabel)-\(refreshID)")
                    .onSubmit { focus.wrappedValue = false }
                    .onChange(of: reps) { _, s in
                        DispatchQueue.main.async {
                            let digits = s.filter(\.isNumber)
                            if digits != s { reps = digits }
                        }
                    }

                let hasNote = (capNote?.isEmpty == false)

                if est1RM > 0 || hasNote {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if est1RM > 0 {
                            HStack(spacing: 6) {
                                Text("Est 1RM ≈ \(Int(est1RM)) lb")
                                    .font(.subheadline)
                                if est1RM > 0 {
                                    if allTimePRBeaten {
                                        PRPill("All-Time PR")
                                    } else if cyclePRBeaten {
                                        PRPill("PR")
                                    }
                                }
                            }
                            FormulaTag(formula: currentFormula)
                                .foregroundColor(.brandAccent)
                        }
                        if let note = capNote, !note.isEmpty {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .onChange(of: done) { old, new in
            guard lastKnownDone == old else {
                lastKnownDone = new
                return
            }

            if !old && new {
                onCheck?(true)
            }
            lastKnownDone = new
        }
        .onAppear {
            lastKnownDone = done
        }
        .task(id: refreshID) {
            lastKnownDone = done
        }
    }
    
    private var cyclePRBeaten: Bool {
        let best = PRStore.shared.bestByCycle[PRKey(cycle: currentCycle, lift: liftLabel)] ?? 0
        return Int(est1RM.rounded()) > best
    }
    private var allTimePRBeaten: Bool {
        let best = PRStore.shared.bestAllTime[liftLabel] ?? 0
        return Int(est1RM.rounded()) > best
    }
}

private struct PRPill: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
            .accessibilityLabel(text)
    }
}

public struct BBBSetRow: View {
    public let setNumber: Int
    public let defaultWeight: Double
    public let defaultReps: Int
    @Binding public var done: Bool
    @Binding public var currentWeight: Double
    @Binding public var currentReps: Int
    public let perSide: [Double]
    public let roundTo: Double
    public var onCheck: ((Bool) -> Void)?
    public let refreshID: String

    @State private var lastKnownDone: Bool = false

    public init(setNumber: Int, defaultWeight: Double, defaultReps: Int, done: Binding<Bool>, currentWeight: Binding<Double>, currentReps: Binding<Int>, perSide: [Double], roundTo: Double, onCheck: ((Bool) -> Void)? = nil, refreshID: String = "") {
        self.setNumber = setNumber
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self._done = done
        self._currentWeight = currentWeight
        self._currentReps = currentReps
        self.perSide = perSide
        self.roundTo = roundTo
        self.onCheck = onCheck
        self.refreshID = refreshID
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $done) { Text("BBB Set \(setNumber)") }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(currentWeight)) lb").font(.headline)
                    if !perSide.isEmpty {
                        Text("Per side: " + LoadFormat.plateList(perSide))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("Weight:").font(.caption).foregroundStyle(.secondary)
                    Button { currentWeight = max(0, currentWeight - roundTo) } label: { Image(systemName: "minus.circle.fill") }
                    Text("\(Int(currentWeight))").font(.caption).monospacedDigit()
                    Button { currentWeight += roundTo } label: { Image(systemName: "plus.circle.fill") }
                    if abs(currentWeight - defaultWeight) > 0.1 {
                        Button { currentWeight = defaultWeight } label: { Image(systemName: "arrow.counterclockwise.circle.fill") }
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Reps:").font(.caption).foregroundStyle(.secondary)
                    Button { currentReps = max(1, currentReps - 1) } label: { Image(systemName: "minus.circle.fill") }
                    Text("\(currentReps)").font(.caption).monospacedDigit()
                    Button { currentReps += 1 } label: { Image(systemName: "plus.circle.fill") }
                    if currentReps != defaultReps {
                        Button { currentReps = defaultReps } label: { Image(systemName: "arrow.counterclockwise.circle.fill") }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .onChange(of: done) { old, new in
            guard lastKnownDone == old else {
                lastKnownDone = new
                return
            }

            if !old && new {
                onCheck?(true)
            }
            lastKnownDone = new
        }
        .onAppear {
            lastKnownDone = done
        }
        .task(id: refreshID) {
            lastKnownDone = done
        }
    }
}

public struct AssistSetRow: View {
    public let setNumber: Int
    public let defaultWeight: Double
    public let defaultReps: Int
    public let hasBarWeight: Bool
    public let usesBarbell: Bool
    @Binding public var done: Bool
    @Binding public var currentWeight: Double
    @Binding public var currentReps: Int
    public let perSide: [Double]
    public let roundTo: Double
    public var onCheck: ((Bool) -> Void)?
    public let refreshID: String

    @State private var lastKnownDone: Bool = false

    public init(setNumber: Int, defaultWeight: Double, defaultReps: Int, hasBarWeight: Bool, usesBarbell: Bool, done: Binding<Bool>, currentWeight: Binding<Double>, currentReps: Binding<Int>, perSide: [Double], roundTo: Double, onCheck: ((Bool) -> Void)? = nil, refreshID: String = "") {
        self.setNumber = setNumber
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.hasBarWeight = hasBarWeight
        self.usesBarbell = usesBarbell
        self._done = done
        self._currentWeight = currentWeight
        self._currentReps = currentReps
        self.perSide = perSide
        self.roundTo = roundTo
        self.onCheck = onCheck
        self.refreshID = refreshID
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $done) { Text("Set \(setNumber)") }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    if hasBarWeight {
                        Text(usesBarbell ? "\(Int(currentWeight)) lb" : "\(Int(currentWeight)) lb (total DBs)")
                            .font(.headline)
                    } else {
                        Text("Bodyweight").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 16) {
                if hasBarWeight {
                    HStack(spacing: 4) {
                        Text("Weight:").font(.caption).foregroundStyle(.secondary)
                        Button { currentWeight = max(0, currentWeight - roundTo) } label: { Image(systemName: "minus.circle.fill") }
                        Text("\(Int(currentWeight))").font(.caption).monospacedDigit()
                        Button { currentWeight += roundTo } label: { Image(systemName: "plus.circle.fill") }
                        if abs(currentWeight - defaultWeight) > 0.1 {
                            Button { currentWeight = defaultWeight } label: { Image(systemName: "arrow.counterclockwise.circle.fill") }
                        }
                    }
                    Spacer()
                }

                HStack(spacing: 4) {
                    Text("Reps:").font(.caption).foregroundStyle(.secondary)
                    Button { currentReps = max(1, currentReps - 1) } label: { Image(systemName: "minus.circle.fill") }
                    Text("\(currentReps)").font(.caption).monospacedDigit()
                    Button { currentReps += 1 } label: { Image(systemName: "plus.circle.fill") }
                    if currentReps != defaultReps {
                        Button { currentReps = defaultReps } label: { Image(systemName: "arrow.counterclockwise.circle.fill") }
                    }
                }

                if !hasBarWeight { Spacer() }
            }
            .buttonStyle(.plain)

            if usesBarbell && !perSide.isEmpty {
                Text("Per side: " + LoadFormat.plateList(perSide))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: done) { old, new in
            guard lastKnownDone == old else {
                lastKnownDone = new
                return
            }

            if !old && new {
                onCheck?(true)
            }
            lastKnownDone = new
        }
        .onAppear {
            lastKnownDone = done
        }
        .task(id: refreshID) {
            lastKnownDone = done
        }
    }
}
