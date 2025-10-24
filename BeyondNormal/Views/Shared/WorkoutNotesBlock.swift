//
//  WorkoutNotesBlock.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/24/25.
//

import SwiftUI

struct WorkoutNotesBlock: View {
    @Binding var text: String
    var body: some View {
        Section {
            TextField("Add notes about today's workout…", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
        } header: {
            Text("Workout Notes")
        }
    }
}
