//
//  JokerSettingsSection.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/24/25.
//

import SwiftUI

struct JokerSettingsSection: View {
    @EnvironmentObject private var settings: ProgramSettings

    var body: some View {
        Section("Joker Sets") {
            Toggle("Enable Joker Sets (for strong days)", isOn: $settings.jokerSetsEnabled)

            Stepper(
                "Trigger on 3s week at ≥ \(settings.jokerTrigger3s) reps",
                value: $settings.jokerTrigger3s,
                in: 4...10
            )
            Stepper(
                "Trigger on 1s week at ≥ \(settings.jokerTrigger1s) reps",
                value: $settings.jokerTrigger1s,
                in: 1...4
            )

            Text("Recommended: 3s ≥ 6 reps, 1s ≥ 2 reps.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            NavigationLink("Advanced") {
                JokerAdvancedSettingsView()
                    .environmentObject(settings)
            }
        }
    }
}

private struct JokerAdvancedSettingsView: View {
    @EnvironmentObject private var settings: ProgramSettings

    var body: some View {
        Form {
            Section("Jump Sizes") {
                Picker("Triples jump (+% of TM)", selection: Binding(
                    get: { Int(round(settings.jokerTripleStepPct * 100)) },
                    set: { settings.jokerTripleStepPct = Double($0) / 100.0 }
                )) {
                    ForEach([5, 7, 10], id: \.self) { Text("\($0)%").tag($0) }
                }

                Picker("Singles jump (+% of TM)", selection: Binding(
                    get: { Int(round(settings.jokerSingleStepPct * 100)) },
                    set: { settings.jokerSingleStepPct = Double($0) / 100.0 }
                )) {
                    ForEach([5, 10, 15], id: \.self) { Text("\($0)%").tag($0) }
                }
            }

            Section("Caps") {
                Picker("Max over TM", selection: Binding(
                    get: { Int(round(settings.jokerMaxOverTMPct * 100)) },
                    set: { settings.jokerMaxOverTMPct = Double($0) / 100.0 }
                )) {
                    ForEach([5, 10, 12, 15], id: \.self) { Text("\($0)%").tag($0) }
                }
            }

            Section {
                Button("Reset Joker Settings to Defaults", role: .destructive) {
                    settings.jokerTrigger3s     = 6
                    settings.jokerTrigger1s     = 2
                    settings.jokerTripleStepPct = 0.05
                    settings.jokerSingleStepPct = 0.10
                    settings.jokerMaxOverTMPct  = 0.10
                }
            }
        }
        .navigationTitle("Joker Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
